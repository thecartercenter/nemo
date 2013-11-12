class Form < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable

  has_many(:questions, :through => :questionings, :order => "questionings.rank")
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy, :inverse_of => :form)
  has_many(:responses, :inverse_of => :form)

  has_many(:versions, :class_name => "FormVersion", :inverse_of => :form, :dependent => :destroy)

  # while a form has many versions, this is a reference to the most up-to-date one
  belongs_to(:current_version, :class_name => "FormVersion")

  before_validation(:normalize_fields)

  validates(:name, :presence => true, :length => {:maximum => 32})
  validate(:name_unique_per_mission)

  before_create(:init_downloads)

  scope(:published, where(:published => true))
  scope(:with_questionings, includes(
    :questionings => [
      :form,
      {:question => {:option_set => :options}},
      {:condition => [:option, :ref_qing]}
    ]
  ).order("questionings.rank"))

  # this scope adds a count of the number of copies of this form, and of those that are published
  # if the form is not a standard, these will just be zero
  scope(:with_copy_counts, select(%{
      forms.*,
      COUNT(DISTINCT copies.id) AS copy_count_col,
      SUM(copies.published) AS published_copy_count_col,
      SUM(copies.responses_count) AS copy_responses_count_col
    })
    .joins("LEFT OUTER JOIN forms copies ON forms.id = copies.standard_id")
    .group("forms.id"))

  scope(:default_order, order('forms.name'))

  replicable :child_assocs => :questionings, :uniqueness => {:field => :name, :style => :sep_words},
    :dont_copy => [:published, :downloads, :responses_count, :questionings_count, :upgrade_needed, :smsable, :current_version_id]

  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end

  def version
    current_version.try(:sequence) || ""
  end

  def version_with_code
    current_version.try(:sequence_and_code) || ""
  end

  def full_name
    # this used to include the form type, but for now it's just name
    name
  end

  # returns whether this form or (if standard) any of its copies have responses, using an eager loaded col if available
  def has_responses?
    if is_standard?
      respond_to?(:copy_responses_count_col) ? (copy_responses_count_col || 0) > 0 : copies.any?(&:has_responses?)
    else
      responses_count > 0
    end
  end

  # returns the number of responses for all copy forms. uses eager loaded col if available
  def copy_responses_count
    if is_standard?
      respond_to?(:copy_responses_count_col) ? (copy_responses_count_col || 0).to_i : copies.inject(0){|sum, c| sum += c.responses_count}
    else
      raise "non-standard forms should not request copy_responses_count"
    end
  end

  # returns whether this form is published OR if standard, if any of its copies are published
  # uses eager loaded col if available
  def published?
    if is_standard?
      respond_to?(:published_copy_count_col) ? (published_copy_count_col || 0) > 0 : copies.any?(&:published?)
    else
      read_attribute(:published)
    end
  end

  # returns number of copies published. uses eager loaded field if available
  def published_copy_count
    # published_copy_count_col may be nil so be careful
    respond_to?(:published_copy_count_col) ? (published_copy_count_col || 0).to_i : copies.find_all(&:published?).size
  end

  def option_sets
    # going through the questionings model as that's the one that is eager-loaded in .with_questionings
    questionings.map(&:question).map(&:option_set).compact.uniq
  end

  def visible_questionings
    questionings.reject{|q| q.hidden}
  end

  # returns questionings that work with sms forms and are not hidden
  def smsable_questionings
    questionings.reject{|q| q.hidden || !q.question.qtype.smsable?}
  end

  def max_rank
    questionings.map{|qing| qing.rank || 0}.max || 0
  end

  # takes a hash of the form {"questioning_id" => "new_rank", ...}
  def update_ranks(new_ranks)
    # set but don't save the new orderings
    questionings.each_index do |i|
      if new_ranks[questionings[i].id.to_s]
        questionings[i].rank = new_ranks[questionings[i].id.to_s].to_i
      end
    end

    # ensure the ranks are sequential
    fix_ranks(:reload => false, :save => false)

    # validate the condition orderings (raises an error if they're invalid)
    questionings.each{|qing| qing.condition_verify_ordering}
  end

  def destroy_questionings(qings)
    qings = Array.wrap(qings)
    transaction do
      # delete the qings
      qings.each do |qing|

        # if this qing has a non-zero answer count, raise an error
        # this is necessary due to bulk deletion operations
        raise DeletionError.new('question_remove_answer_error') if qing_answer_count(qing) > 0

        questionings.delete(qing)
        qing.destroy
      end

      # fix the ranks
      fix_ranks(:reload => false, :save => true)

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
      save(:validate => false)
    end
  end

  # unpublishes this form
  def unpublish!
    self.published = false
    save(:validate => false)
  end

  # increments the download counter
  def add_download
    self.downloads += 1
    save(:validate => false)
  end

  # upgrades the version of the form and saves it
  # also resets the download count
  def upgrade_version!
    raise "standard forms should not be versioned" if is_standard?

    if current_version
      self.current_version = current_version.upgrade
    else
      self.build_current_version(:form_id => id)
    end

    # since we've upgraded, we can lower the upgrade flag
    self.upgrade_needed = false

    # reset downloads since we are only interested in downloads of present version
    self.downloads = 0

    save(:validate => false)
  end

  # sets the upgrade flag so that the form will be upgraded when next published
  def flag_for_upgrade!
    raise "standard forms should not be versioned" if is_standard?

    self.upgrade_needed = true
    save(:validate => false)
  end

  # checks if this form doesn't have any non-required questions
  # if options[:smsable] is set, specifically looks for non-required questions that are smsable
  def all_required?(options = {})
    @all_required ||= visible_questionings.reject{|qing| qing.required? || (options[:smsable] ? !qing.question.smsable? : false)}.empty?
  end

  # efficiently gets the number of answers for the given questioning on this form
  # or if the form is standard, for the given questioning on any copies
  def qing_answer_count(qing)
    # fetch the counts if not already fetched
    if !@answer_counts

      # if form is standard, look for answers for copy questionings, since the std questioning will never have answers
      joins = if is_standard?
        %{LEFT OUTER JOIN questionings copies ON questionings.id = copies.standard_id
          LEFT OUTER JOIN answers ON answers.questioning_id = copies.id}
      else
        "LEFT OUTER JOIN answers ON answers.questioning_id = questionings.id"
      end

      @answer_counts = Questioning.find_by_sql([%{
        SELECT questionings.id, COUNT(DISTINCT answers.id) AS answer_count
        FROM questionings #{joins}
        WHERE questionings.form_id = ?
        GROUP BY questionings.id
      }, id]).index_by(&:id)
    end

    # get the desired count
    @answer_counts[qing.id].try(:answer_count) || 0
  end

  # ensures question ranks are sequential
  def fix_ranks(options = {})
    options[:reload] = true if options[:reload].nil?
    options[:save] = true if options[:save].nil?
    questionings(options[:reload]).sort_by{|qing| qing.rank}.each_with_index{|qing, idx| qing.rank = idx + 1}
    save(:validate => false) if options[:save]
  end

  private
    def init_downloads
      self.downloads = 0
      return true
    end

    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end

    def normalize_fields
      self.name = name.strip
      return true
    end

end
