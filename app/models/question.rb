# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: questions
#
#  id                        :uuid             not null, primary key
#  access_level              :string(255)      default("inherit"), not null
#  auto_increment            :boolean          default(FALSE), not null
#  canonical_name            :text             not null
#  code                      :string(255)      not null
#  hint_translations         :jsonb
#  key                       :boolean          default(FALSE), not null
#  maximum                   :decimal(15, 8)
#  maxstrictly               :boolean
#  media_prompt_content_type :string
#  media_prompt_file_name    :string
#  media_prompt_file_size    :integer
#  media_prompt_updated_at   :datetime
#  metadata_type             :string
#  minimum                   :decimal(15, 8)
#  minstrictly               :boolean
#  name_translations         :jsonb            not null
#  qtype_name                :string(255)      not null
#  reference                 :string
#  standard_copy             :boolean          default(FALSE), not null
#  text_type_for_sms         :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  mission_id                :uuid
#  option_set_id             :uuid
#  original_id               :uuid
#
# Indexes
#
#  index_questions_on_mission_id           (mission_id)
#  index_questions_on_mission_id_and_code  (mission_id,code) UNIQUE
#  index_questions_on_option_set_id        (option_set_id)
#  index_questions_on_original_id          (original_id)
#  index_questions_on_qtype_name           (qtype_name)
#
# Foreign Keys
#
#  questions_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  questions_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# A question on a form
class Question < ApplicationRecord
  include Translatable
  include Replication::Replicable
  include Replication::Standardizable
  include MissionBased
  include ODK::Mediable
  include Wisper.model

  # Note that the maximum allowable length is 22 chars (1 letter plus 21 letters/numbers)
  # The user is told that the max is 20.
  # This is because we need to leave room for additional digits at the end during replication to
  # maintain uniqueness.
  CODE_FORMAT = "[a-zA-Z][a-zA-Z0-9]{1,21}"
  API_ACCESS_LEVELS = %w[inherit private].freeze
  METADATA_TYPES = %w[formstart formend].freeze

  belongs_to :option_set, inverse_of: :questions, autosave: true
  has_many :questionings, dependent: :destroy, autosave: true, inverse_of: :question
  has_many :response_nodes, through: :questionings
  has_many :forms, through: :questionings
  has_many :calculations, class_name: "Report::Calculation", # see below for dependent: :destroy alternative
                          foreign_key: "question1_id", inverse_of: :question1
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  odk_media_attachment :media_prompt

  accepts_nested_attributes_for :tags, reject_if: proc { |attributes| attributes[:name].blank? }

  before_validation :normalize
  before_save :set_filename
  before_save :check_condition_integrity
  after_destroy :check_condition_integrity
  after_save :update_forms

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { calculations.each(&:question_destroyed) }

  validates :code, presence: true
  validates :code, format: {with: /\A#{CODE_FORMAT}\z/}, unless: -> { code.blank? }
  validates :qtype_name, presence: true
  validates :option_set, presence: true, if: -> { qtype && has_options? }
  %w[minimum maximum].each do |field|
    # Numeric limits are due to column floating point restrictions
    validates :"casted_#{field}", numericality: {allow_blank: true, greater_than: -1e7, less_than: 1e7}
  end
  validate :code_unique_per_mission
  validate :at_least_one_name
  validate :valid_reference_url

  scope :by_code, -> { order("questions.code") }
  scope :with_code, ->(c) { where("LOWER(code) = ?", c.downcase) }
  scope :default_order, -> { by_code }
  scope :select_types, -> { where(qtype_name: %w[select_one select_multiple]) }
  scope :with_forms, -> { includes(:forms) }
  scope :with_type_property, lambda { |property|
    where(qtype_name: QuestionType.with_property(property).map(&:name))
  }
  scope :not_in_form, lambda { |form|
                        where("(questions.id NOT IN (
                          SELECT question_id FROM form_items
                            WHERE type = 'Questioning' AND form_id = ?))", form.id)
                      }

  translates :name, :hint

  delegate :smsable?,
    :has_options?,
    :temporal?,
    :numeric?,
    :textual?,
    :printable?,
    :multimedia?,
    :odk_tag,
    :odk_name,
    :select_multiple?,
    to: :qtype

  delegate :options,
    :first_level_option_nodes,
    :all_options,
    :first_leaf_option_node,
    :first_level_options,
    :multilevel?,
    :level_count,
    :level,
    :levels,
    :sms_formatting_as_text?,
    :sms_formatting_as_appendix?,
    to: :option_set, allow_nil: true

  replicable child_assocs: %i[option_set taggings], backwards_assocs: :questioning, sync: :code,
             uniqueness: {field: :code, style: :camel_case}, dont_copy: %i[key access_level],
             compatibility: %i[qtype_name option_set_id]

  clone_options follow: %i[option_set taggings]

  # returns N questions marked as key questions, sorted by the number of forms they appear in
  def self.key(num)
    where(key: true).all.sort_by { |q| q.questionings.size }[0...num]
  end

  # Returns name, or a default value (not nil) if name not defined.
  def name_or_none
    name || ""
  end

  def preordered_option_nodes
    option_set.try(:preordered_option_nodes) || []
  end

  # returns the question type object associated with this question
  def qtype
    QuestionType[qtype_name]
  end

  def location_type?
    qtype_name == "location"
  end

  def conditions?
    Condition.referring_to_question(self).any?
  end

  def geographic?
    location_type? || qtype_name == "select_one" && option_set.geographic?
  end

  # DEPRECATED: this method should go away later
  def select_options
    (first_level_options || []).map { |o| [o.name, o.id] }
  end

  # gets the number of forms which with this question is directly associated
  def form_count
    forms.count
  end

  def answer_count
    standard? ? copies.to_a.sum(&:answer_count) : response_nodes.count
  end

  def data?
    answer_count.positive?
  end

  def in_use?
    forms.any?
  end

  # determines if the question appears on any published forms
  def published?
    !standard? && forms.any?(&:not_draft?)
  end

  # checks if any associated forms are smsable
  # NOTE different from plain Question.smsable?
  def form_smsable?
    forms.any?(&:smsable?)
  end

  # an odk (xpath) expression of any question contraints
  def odk_constraint
    exps = []
    exps << ". #{minstrictly ? '>' : '>='} #{casted_minimum}" if minimum
    exps << ". #{maxstrictly ? '<' : '<='} #{casted_maximum}" if maximum
    exps.empty? ? nil : "(" + exps.join(" and ") + ")"
  end

  def qing_ids
    questionings.pluck(:id)
  end

  # convert value stored as decimal to integer if integer question type
  def casted_minimum
    minimum.blank? ? nil : (qtype_name == "decimal" ? minimum : minimum.to_i)
  end

  def casted_maximum
    maximum.blank? ? nil : (qtype_name == "decimal" ? maximum : maximum.to_i)
  end

  def casted_minimum=(n)
    self.minimum = n
    self.minimum = casted_minimum
  end

  def casted_maximum=(n)
    self.maximum = n
    self.maximum = casted_maximum
  end

  def min_max_error_msg
    return nil unless minimum || maximum

    clauses = []
    or_eq = I18n.t("question.maxmin.or_eq") + " "
    if minimum
      clauses << I18n.t("question.maxmin.gt") + " " + (minstrictly ? "" : or_eq) + casted_minimum.to_s
    end
    if maximum
      clauses << I18n.t("question.maxmin.lt") + " " + (maxstrictly ? "" : or_eq) + casted_maximum.to_s
    end
    I18n.t("layout.must_be") + " " + clauses.join(" " + I18n.t("common.and") + " ")
  end

  # returns sorted list of form ids related to this form
  def form_ids
    forms.collect(&:id).sort
  end

  # gets a comma separated list of all related forms names
  def form_names
    forms.map(&:name).join(", ")
  end

  def constraint_changed?
    %w[minimum maximum minstrictly maxstrictly].any? { |f| send("#{f}_changed?") }
  end

  # checks if any core fields (type, option set, constraints) changed
  def core_changed?
    qtype_name_changed? || option_set_id_changed? || constraint_changed?
  end

  # shortcut accessor
  def option_levels
    option_set.present? ? option_set.option_levels : []
  end

  # This should be able to be done by adding `order: :name` to the association,
  # but that causes a cryptic SQL error
  def sorted_tags
    tags.order(:name)
  end

  private

  def code_unique_per_mission
    errors.add(:code, :taken) unless unique_in_mission?(:code)
  end

  def normalize
    self.code = code.strip

    if qtype.try(:numeric?)
      self.minstrictly = false if !minimum.nil? && minstrictly.nil?
      self.maxstrictly = false if !maximum.nil? && maxstrictly.nil?
      self.minstrictly = nil if minimum.nil?
      self.maxstrictly = nil if maximum.nil?
    else
      self.minimum = nil
      self.maximum = nil
      self.minstrictly = nil
      self.maxstrictly = nil
    end

    self.metadata_type = qtype_name == "datetime" ? metadata_type.presence : nil

    true
  end

  def set_filename
    media_prompt.assign_attributes(filename: unique_media_prompt_filename) if media_prompt?
  end

  # Return a unique filename to curb collisions e.g. on ODK,
  # maintaining the extension e.g. ".mp3".
  def unique_media_prompt_filename
    return nil unless media_prompt?
    "#{id}_media_prompt#{File.extname(media_prompt.filename.to_s)}"
  end

  def at_least_one_name
    errors.add(:base, :at_least_one_name) if name.blank?
  end

  def check_condition_integrity
    Condition.check_integrity_after_question_change(self)
  end

  def update_forms
    forms.each(&:touch)
  end

  def valid_reference_url
    return if reference.blank?

    url = URI.parse(reference)
    errors.add(:reference, :invalid) unless url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS)
  end
end
