# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: forms
#
#  id                    :uuid             not null, primary key
#  access_level          :string(255)      default("private"), not null
#  allow_incomplete      :boolean          default(FALSE), not null
#  authenticate_sms      :boolean          default(TRUE), not null
#  default_response_name :string
#  downloads             :integer
#  name                  :string(255)      not null
#  sms_relay             :boolean          default(FALSE), not null
#  smsable               :boolean          default(FALSE), not null
#  standard_copy         :boolean          default(FALSE), not null
#  status                :string           default("draft"), not null
#  status_changed_at     :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  mission_id            :uuid
#  original_id           :uuid
#  root_id               :uuid
#
# Indexes
#
#  index_forms_on_mission_id   (mission_id)
#  index_forms_on_original_id  (original_id)
#  index_forms_on_root_id      (root_id) UNIQUE
#  index_forms_on_status       (status)
#
# Foreign Keys
#
#  forms_mission_id_fkey   (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  forms_original_id_fkey  (original_id => forms.id) ON DELETE => nullify ON UPDATE => restrict
#  forms_root_id_fkey      (root_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# A survey or checklist.
class Form < ApplicationRecord
  include Replication::Replicable
  include Replication::Standardizable
  include MissionBased

  def self.receivable_association
    {name: :form_forwardings, fk: :recipient}
  end
  include Receivable

  API_ACCESS_LEVELS = %w[private public].freeze

  has_many :responses, inverse_of: :form, dependent: :destroy
  has_many :versions, -> { order(:number) }, class_name: "FormVersion", inverse_of: :form,
                                             dependent: :destroy
  has_many :whitelistings, as: :whitelistable, class_name: "Whitelisting", dependent: :destroy
  has_many :standard_form_reports, class_name: "Report::StandardFormReport", dependent: :destroy

  # For some reason dependent: :destroy doesn't work with this assoc. See destroy_items for workaround.
  belongs_to :root_group, autosave: true, class_name: "QingGroup", foreign_key: :root_id

  before_create :init_downloads
  before_validation :normalize
  after_create :create_root_group
  before_destroy :destroy_items

  attr_writer :minimum_version_id
  after_save :update_minimum

  validates :name, presence: true, length: {maximum: 32}
  validate :name_unique_per_mission
  validates_with Forms::DynamicPatternValidator, field_name: :default_response_name

  scope :live, -> { where(status: "live") }
  scope :by_name, -> { order(:name) }
  scope :by_status, -> { order("CASE status WHEN 'draft' THEN 2 ELSE 1 END") }
  scope :default_order, -> { by_name }
  scope :with_responses_counts, lambda {
    forms = Form.arel_table
    responses = Response.arel_table
    count_subquery = Response.select(responses[:id].count)
      .where(responses[:form_id].eq(forms[:id])).arel.as("AS responses_count")
    select(forms[Arel.star]).select(count_subquery)
  }

  delegate :children, :sorted_children, :visible_children, :c, :sc,
    :descendants, :child_groups, to: :root_group
  delegate :code, to: :current_version
  delegate :number, to: :current_version
  delegate :number, to: :minimum_version, prefix: true, allow_nil: true
  delegate :override_code, to: :mission

  replicable child_assocs: :root_group, uniqueness: {field: :name, style: :sep_words},
             dont_copy: %i[status status_changed_at downloads
                           smsable allow_incomplete access_level]

  # remove heirarchy of objects
  def self.terminate_sub_relationships(form_ids)
    Form.where(id: form_ids).update_all(original_id: nil, root_id: nil)
    FormVersion.where(form_id: form_ids).delete_all
  end

  # Gets a cache key based on the mission and the max (latest) status_changed_at value.
  def self.odk_index_cache_key(options)
    # Note that since we're using maximum method, dates don't seem to be TZ adjusted on load,
    # which is fine as long as it's consistent.
    max_status_changed_at =
      if for_mission(options[:mission]).live.any?
        for_mission(options[:mission]).maximum(:status_changed_at).utc.to_s(:cache_datetime)
      else
        "no-pubd-forms"
      end
    "odk-form-list/mission-#{options[:mission].id}/#{max_status_changed_at}"
  end

  def condition_computer
    @condition_computer ||= Forms::ConditionComputer.new(self)
  end

  def add_questions_to_top_level(questions)
    Array.wrap(questions).each_with_index do |q, _i|
      # We don't validate because there is no opportunity to present the error to the user,
      # and if there is an error, it's not due to something the user just did since all they did was
      # choose a question to add.
      Questioning.new(mission: mission, form: self, question: q, parent: root_group).save(validate: false)
    end
  end

  def root_questionings(_reload = false)
    # Not memoizing this because it causes all sorts of problems.
    root_group ? root_group.sorted_children.reject { |q| q.is_a?(QingGroup) } : []
  end

  def preordered_items(eager_load: nil)
    root_group.try(:preordered_descendants, eager_load: eager_load) || []
  end

  def odk_download_cache_key
    "odk-form/#{id}-#{status_changed_at}"
  end

  def api_user_id_can_see?(api_user_id)
    access_level == "public" || access_level == "protected" &&
      whitelistings.pluck(:user_id).include?(api_user_id)
  end

  def api_visible_questions
    questions.select { |q| q.access_level == "inherit" }
  end

  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899_999_999) + 100_000_000}"
  end

  def data?
    responses.any?
  end

  def full_name
    # this used to include the form type, but for now it's just name
    name
  end

  # returns whether this form has responses; standard forms never have responses
  def has_responses?
    !standard? && responses_count.positive?
  end

  def responses_count
    # Use the eager loaded attribute if it's present, else query the association.
    self[:responses_count] || responses.count
  end

  def copy_count
    copies.count
  end

  def copy_responses_count
    raise "non-standard forms should not request copy_responses_count" unless standard?
    copies.to_a.sum(&:responses_count)
  end

  def published?
    !standard? && !draft?
  end

  def option_sets
    questionings.map(&:question).map(&:option_set).compact.uniq
  end

  def option_sets_with_appendix
    option_sets.select { |os| os.sms_formatting == "appendix" }
  end

  # Returns all descendant questionings in one flat array, sorted in pre-order traversal and rank order.
  # Uses FormItem.preordered_descendants which eager loads questions and option sets.
  def questionings
    root_group&.preordered_descendants(
      eager_load: {question: {option_set: :root_node}}, type: "Questioning") || []
  end

  def visible_questionings
    questionings.reject(&:hidden?)
  end

  def questions(_reload = false)
    questionings.map(&:question)
  end

  # returns hash of questionings that work with sms forms and are not hidden
  def smsable_questionings
    smsable_questionings = questionings.select(&:smsable?)
    smsable_questionings.map.with_index { |q, i| [i + 1, q] }.to_h
  end

  def questioning_with_code(code)
    questionings.detect { |q| q.code == code }
  end

  # Gets the last Questioning on the form, ignoring the group structure.
  def last_qing
    children.where(type: "Questioning").order(:rank).last
  end

  def update_status(new_status)
    return if new_status == status
    # Don't run validations in case form has become invalid due to a migration or other change.
    update_columns(status: new_status, status_changed_at: Time.current)

    # Ensure the form has a version if it's becoming live.
    increment_version if live? && current_version.nil?
  end

  def live?
    status == "live"
  end

  def paused?
    status == "paused"
  end

  def draft?
    status == "draft"
  end

  def not_draft?
    status != "draft"
  end

  # increments the download counter
  def add_download
    self.downloads += 1
    save(validate: false)
  end

  def current_version
    versions.find_by(current: true)
  end

  # This getter serves a form field.
  def minimum_version_id
    return @minimum_version_id if defined?(@minimum_version_id)
    persisted_minimum_version&.id
  end

  # Finds the minimum version by checking the ephemeral attribute instead of the DB in case
  # a new value hasn't been persisted yet. Use persisted_minimum_version to get the persisted one.
  def minimum_version
    versions.find(minimum_version_id) if minimum_version_id.present?
  end

  # Creates a new version code/number for the form. Also resets the download count to zero.
  def increment_version
    raise "standard forms should not be versioned" if standard?

    had_current_version = current_version.present?
    current_version.update!(current: false) if had_current_version
    versions.create!(current: true, minimum: !had_current_version)

    # Reset downloads since we are only interested in downloads of present version.
    # Touch last changed so the cache key gets bumped.
    update_columns(downloads: 0, status_changed_at: Time.current)
  end

  # efficiently gets the number of answers for the given questioning on this form
  # returns zero if form is standard
  def qing_answer_count(qing)
    return 0 if standard?

    @answer_counts ||= Questioning.find_by_sql([%{
      SELECT form_items.id, COUNT(DISTINCT answers.id) AS answer_count
      FROM form_items
        LEFT OUTER JOIN answers ON answers.questioning_id = form_items.id
          AND form_items.type = 'Questioning'
      WHERE form_items.form_id = ?
      GROUP BY form_items.id
    }, id]).index_by(&:id)

    # get the desired count
    @answer_counts[qing.id].try(:answer_count) || 0
  end

  private

  def init_downloads
    self.downloads = 0
    true
  end

  def create_root_group
    create_root_group!(mission: mission, form: self)
    save!
  end

  def update_minimum
    return unless defined?(@minimum_version_id)
    persisted_minimum_version&.update!(minimum: false)
    minimum_version.update!(minimum: true)
  end

  # The persisted version, regardless of ephemeral @minimum_version_id
  def persisted_minimum_version
    versions.find_by(minimum: true)
  end

  # Nullifies the root_id foreign key and then deletes all items before deleting the form.
  # This ensures root_id constraint is not violated.
  # By default, has_ancestry destroys all children of a destroyed group, so this should cascade down.
  def destroy_items
    group_to_destroy = root_group
    update_columns(root_id: nil)
    group_to_destroy.destroy
  end

  def name_unique_per_mission
    errors.add(:name, :taken) unless unique_in_mission?(:name)
  end

  def normalize
    self.name = name.strip
    self.default_response_name = default_response_name.try(:strip).presence
    true
  end
end
