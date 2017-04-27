class Form < ApplicationRecord
  include MissionBased, FormVersionable, Replication::Standardizable, Replication::Replicable

  def self.receivable_association
    {name: :form_forwardings, fk: :recipient}
  end
  include Receivable

  API_ACCESS_LEVELS = %w(private public)

  has_many(:responses, inverse_of: :form)
  has_many(:versions, class_name: "FormVersion", inverse_of: :form, dependent: :destroy)
  has_many(:whitelistings, as: :whitelistable, class_name: "Whitelisting", dependent: :destroy)
  has_many(:standard_form_reports, class_name: "Report::StandardFormReport", dependent: :destroy)

  # while a form has many versions, this is a reference to the most up-to-date one
  belongs_to(:current_version, class_name: "FormVersion")

  # For some reason dependent: :destroy doesn't work with this assoc.
  belongs_to :root_group, autosave: true, class_name: "QingGroup", foreign_key: :root_id

  before_validation(:normalize_fields)
  before_save(:update_pub_changed_at)

  # For some reason this works but dependent: :destroy doesn't.
  before_destroy { root_group.destroy }

  validates(:name, presence: true, length: {maximum: 32})
  validate(:name_unique_per_mission)

  before_create(:init_downloads)

  scope(:published, -> { where(published: true) })

  # this scope adds a count of the questionings on this form and
  # the number of copies of this form, and of those that are published
  # if the form is not a standard, these will just be zero
  scope(:with_questioning_and_copy_counts, -> { select(%{
      forms.*,
      COUNT(DISTINCT form_items.id) AS questionings_count_col,
      COUNT(DISTINCT copies.id) AS copy_count_col,
      SUM(CASE copies.published WHEN true THEN 1 ELSE 0 END) AS published_copy_count_col,
      SUM(copies.responses_count) AS copy_responses_count_col
    })
    .joins(%{
      LEFT OUTER JOIN form_items ON forms.id = form_items.form_id AND form_items.type = 'Questioning'
      LEFT OUTER JOIN forms copies ON forms.id = copies.original_id AND copies.standard_copy = true
    })
    .group("forms.id") })

  scope(:by_name, -> { order("forms.name") })
  scope(:default_order, -> { by_name })

  delegate :arrange_descendants,
    :children,
    :ordered_children,
    :c,
    :descendants,
    :child_groups,
    to: :root_group

  delegate :code, to: :current_version

  replicable child_assocs: :root_group, uniqueness: {field: :name, style: :sep_words},
    dont_copy: [:published, :pub_changed_at, :downloads, :responses_count, :upgrade_needed,
      :smsable, :current_version_id, :allow_incomplete, :access_level, :root_id]


  # remove heirarchy of objects
  def self.terminate_sub_relationships(form_ids)
    Form.where(id: form_ids).update_all(original_id: nil)
    FormVersion.where(form_id: form_ids).delete_all
    Questioning.where(form_id: form_ids).delete_all
  end

  # Gets a cache key based on the mission and the max (latest) pub_changed_at value.
  def self.odk_index_cache_key(options)
    # Note that since we're using maximum method, dates don't seem to be TZ adjusted on load, which is fine as long as it's consistent.
    max_pub_changed_at = if for_mission(options[:mission]).published.any?
      for_mission(options[:mission]).maximum(:pub_changed_at).utc.to_s(:cache_datetime)
    else
      'no-pubd-forms'
    end
    "odk-form-list/mission-#{options[:mission].id}/#{max_pub_changed_at}"
  end

  def add_questions_to_top_level(questions)
    Array.wrap(questions).each_with_index do |q, i|
      Questioning.create!(mission: mission, form: self, question: q, parent: root_group)
    end
  end

  def root_questionings(reload = false)
    # Not memoizing this because it causes all sorts of problems.
    root_group ? root_group.children.order(:rank).reject{ |q| q.is_a?(QingGroup) } : []
  end

  def odk_download_cache_key
    "odk-form/#{id}-#{pub_changed_at}"
  end

  def api_user_id_can_see?(api_user_id)
    access_level == "public" || access_level == "protected" &&
      whitelistings.pluck(:user_id).include?(api_user_id)
  end

  def api_visible_questions
    questions.select{ |q| q.access_level == "inherit" }
  end

  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end

  def version
    current_version.try(:sequence) || ""
  end

  def version_with_code
    current_version.try(:sequence_and_code) || ""
  end

  def has_questions?
    questionings.any?
  end

  def full_name
    # this used to include the form type, but for now it's just name
    name
  end

  # current override code for incomplete responses
  def override_code
    mission.override_code
  end

  # returns whether this form has responses; standard forms never have responses
  def has_responses?
    is_standard? ? false : responses_count > 0
  end

  # returns the number of responses for all copy forms. uses eager loaded col if available
  def copy_responses_count
    if is_standard?
      respond_to?(:copy_responses_count_col) ? (copy_responses_count_col || 0).to_i : copies.inject(0){|sum, c| sum += c.responses_count}
    else
      raise "non-standard forms should not request copy_responses_count"
    end
  end

  # Returns whether this form is published, using eager loaded col if available.
  # Standard forms are never published.
  def published?
    is_standard? ? false : read_attribute(:published)
  end

  # returns number of copies published. uses eager loaded field if available
  def published_copy_count
    # published_copy_count_col may be nil so be careful
    respond_to?(:published_copy_count_col) ? (published_copy_count_col || 0).to_i : copies.find_all(&:published?).size
  end

  # returns number of questionings on the form. uses eager loaded field if available.
  def questionings_count
    respond_to?(:questionings_count_col) ? (questionings_count_col || 0).to_i : questionings.count
  end

  def option_sets
    questionings.map(&:question).map(&:option_set).compact.uniq
  end

  def option_sets_with_appendix
    option_sets.select { |os| os.sms_formatting == "appendix" }
  end

  # Returns all descendant questionings in one flat array, sorted in traversal order.
  def questionings(reload = false)
    if root_group
      root_group.descendant_questionings.flatten
    else
      []
    end
  end

  def questions(reload = false)
    questionings.map(&:question)
  end

  def visible_questionings
    questionings.reject { |q| q.hidden? }
  end

  # returns hash of questionings that work with sms forms and are not hidden
  def smsable_questionings
    smsable_questionings = questionings.select(&:smsable?)
    smsable_questionings.map.with_index { |q, i| [i + 1, q] }.to_h
  end

  def questioning_with_code(c)
    questionings.detect{ |q| q.code == c }
  end

  # Loads all options used on the form in a constant number of queries.
  def all_options
    OptionSet.all_options_for_sets(questions.map(&:option_set_id).compact)
  end

  # Gets all first level option nodes with options eagerly loaded.
  def all_first_level_option_nodes
    OptionSet.first_level_option_nodes_for_sets(questions.map(&:option_set_id).compact)
  end

  # Gets the last Questioning on the form, ignoring the group structure.
  def last_qing
    children.where(type: 'Questioning').order(:rank).last
  end

  # Whether this form needs an accompanying manifest for odk.
  def needs_odk_manifest?
    # For now this is IFF there are any multilevel option sets
    @needs_odk_manifest ||= option_sets.any?(&:multilevel?)
  end

  def destroy_questionings(qings)
    qings = Array.wrap(qings)
    transaction do
      # delete the qings, last first, to avoid version bump if possible.
      qings.sort_by(&:rank).reverse.each do |qing|

        # if this qing has a non-zero answer count, raise an error
        # this is necessary due to bulk deletion operations
        raise DeletionError.new('question_remove_answer_error') if qing_answer_count(qing) > 0

        qing.destroy
      end

      save
    end
  end

  # publishes the form
  # upgrades the version if necessary
  def publish!
    self.published = true

    # upgrade if necessary
    if upgrade_needed? || current_version.nil?
      upgrade_version!
    else
      save(validate: false)
    end
  end

  # unpublishes this form
  def unpublish!
    self.published = false
    save(validate: false)
  end

  def verb
    published? ? 'unpublish' : 'publish'
  end

  # increments the download counter
  def add_download
    self.downloads += 1
    save(validate: false)
  end

  # upgrades the version of the form and saves it
  # also resets the download count
  def upgrade_version!
    raise "standard forms should not be versioned" if is_standard?

    if current_version
      self.current_version = current_version.upgrade
    else
      self.build_current_version(form_id: id)
    end

    # since we've upgraded, we can lower the upgrade flag
    self.upgrade_needed = false

    # reset downloads since we are only interested in downloads of present version
    self.downloads = 0

    save(validate: false)
  end

  # sets the upgrade flag so that the form will be upgraded when next published
  def flag_for_upgrade!
    raise "standard forms should not be versioned" if is_standard?

    self.upgrade_needed = true
    save(validate: false)
  end

  # checks if this form doesn't have any non-required questions
  # if options[:smsable] is set, specifically looks for non-required questions that are smsable
  def all_required?(options = {})
    @all_required ||= visible_questionings.reject{|qing| qing.required? || (options[:smsable] ? !qing.question.smsable? : false)}.empty?
  end

  # efficiently gets the number of answers for the given questioning on this form
  # returns zero if form is standard
  def qing_answer_count(qing)
    return 0 if is_standard?

    @answer_counts ||= Questioning.find_by_sql([%{
      SELECT form_items.id, COUNT(DISTINCT answers.id) AS answer_count
      FROM form_items LEFT OUTER JOIN answers ON answers.questioning_id = form_items.id AND form_items.type = 'Questioning'
      WHERE form_items.form_id = ?
      GROUP BY form_items.id
    }, id]).index_by(&:id)

    # get the desired count
    @answer_counts[qing.id].try(:answer_count) || 0
  end

  def has_white_listed_user?(user_id)
    whitelistings.where(user_id: user_id).exists?
  end

  private

  def init_downloads
    self.downloads = 0
    true
  end

  def name_unique_per_mission
    errors.add(:name, :taken) unless unique_in_mission?(:name)
  end

  def normalize_fields
    self.name = name.strip
    true
  end

  def update_pub_changed_at
    self.pub_changed_at = Time.now if published_changed?
    true
  end
end
