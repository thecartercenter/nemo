# a question on a form
class Question < ApplicationRecord
  include MissionBased, Replication::Standardizable, Replication::Replicable, FormVersionable, Translatable

  acts_as_paranoid

  # Note that the maximum allowable length is 22 chars (1 letter plus 21 letters/numbers)
  # The user is told that the max is 20.
  # This is because we need to leave room for additional digits at the end during replication to maintain uniqueness.
  CODE_FORMAT = "[a-zA-Z][a-zA-Z0-9]{1,21}"
  API_ACCESS_LEVELS = %w(inherit private)
  METADATA_TYPES = %w(formstart formend)

  belongs_to :option_set, inverse_of: :questions, autosave: true
  has_many :questionings, dependent: :destroy, autosave: true, inverse_of: :question
  has_many :answers, through: :questionings
  has_many :referring_conditions, through: :questionings
  has_many :forms, through: :questionings
  has_many :calculations, class_name: 'Report::Calculation',
    foreign_key: 'question1_id', inverse_of: :question1
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  has_attached_file :audio_prompt
  validates_attachment_content_type :audio_prompt, content_type: [%r{\Aaudio/.*\Z}, "video/ogg"]
  validates_attachment_file_name :audio_prompt, matches: /\.(mp3|ogg|wav)\Z/i

  accepts_nested_attributes_for :tags, reject_if: proc { |attributes| attributes[:name].blank? }

  before_validation :normalize
  before_save :check_condition_integrity

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { calculations.each(&:question_destroyed) }

  after_destroy :check_condition_integrity

  validates :code, presence: true
  validates :code, format: {with: /\A#{CODE_FORMAT}\z/}, unless: -> { code.blank? }
  validates :qtype_name, presence: true
  validates :option_set, presence: true, if: -> { qtype && has_options? }
  %w(minimum maximum).each do |field|
    # Numeric limits are due to column floating point restrictions
    validates :"casted_#{field}", numericality: { allow_blank: true, greater_than: -1e7, less_than: 1e7 }
  end
  validate :code_unique_per_mission
  validate :at_least_one_name

  scope :by_code, -> { order('questions.code') }
  scope :with_code, ->(c) { where("LOWER(code) = ?", c.downcase) }
  scope :default_order, -> { by_code }
  scope :select_types, -> { where(:qtype_name => %w(select_one select_multiple)) }
  scope :with_forms, -> { includes(:forms) }
  scope :reportable, -> { where.not(qtype_name: %w(image annotated_image signature sketch audio video)) }
  scope :not_in_form, ->(form) { where("(questions.id NOT IN (
    SELECT question_id FROM form_items
      WHERE type = 'Questioning' AND form_id = ? AND deleted_at IS NULL))", form.id) }

  translates :name, :hint

  delegate :smsable?,
           :has_options?,
           :temporal?,
           :numeric?,
           :printable?,
           :multimedia?,
           :odk_tag,
           :odk_name,
           :select_multiple?,
           to: :qtype

  delegate :options,
           :first_level_option_nodes,
           :all_options,
           :first_leaf_option,
           :first_leaf_option_node,
           :first_level_options,
           :multilevel?,
           :level_count,
           :level,
           :levels,
           :sms_formatting_as_text?,
           :sms_formatting_as_appendix?,
           to: :option_set, allow_nil: true

  replicable child_assocs: :option_set, backwards_assocs: :questioning, sync: :code,
    uniqueness: {field: :code, style: :camel_case}, dont_copy: [:key, :access_level, :option_set_id],
    compatibility: [:qtype_name, :option_set_id]

  # returns N questions marked as key questions, sorted by the number of forms they appear in
  def self.key(n)
    where(:key => true).all.sort_by{|q| q.questionings.size}[0...n]
  end

  def self.search_qualifiers
    [
      Search::Qualifier.new(name: "code", col: "questions.code", type: :text),
      Search::Qualifier.new(name: "title", col: "questions.name_translations", type: :translated, default: true),
      Search::Qualifier.new(name: "type", col: "questions.qtype_name", preprocessor: ->(s){ s.gsub(/[\-]/, '_') }),
      Search::Qualifier.new(name: "tag", col: "tags.name", assoc: :tags, :type => :text),
    ]
  end

  # searches for questions
  # scope parameter is not used in Question search
  def self.do_search(relation, query, _scope)
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # apply the needed associations
    relation = relation.joins(search.associations)

    # apply the conditions
    relation = relation.where(search.sql)
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

  def has_conditions?
    Condition.referring_to_question(self).any?
  end

  # determines if a question has answers
  def has_answers?
    answers.count > 0
  end

  def geographic?
    location_type? || qtype_name == "select_one" && option_set.geographic?
  end

  # DEPRECATED: this method should go away later
  def select_options
    (first_level_options || []).map{ |o| [o.name, o.id] }
  end

  # gets the number of forms which with this question is directly associated
  def form_count
    forms.count
  end

  def answer_count
    is_standard? ? copies.to_a.sum(&:answer_count) : answers.count
  end

  def has_answers?
    answer_count > 0
  end

  # determines if the question appears on any published forms
  def published?
    is_standard? ? false : forms.any?(&:published?)
  end

  # checks if any associated forms are smsable
  # NOTE different from plain Question.smsable?
  def form_smsable?
    forms.any?(&:smsable?)
  end

  # an odk-friendly unique code
  def odk_code
    "q#{id}"
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
    minimum.blank? ? nil : (qtype_name == 'decimal' ? minimum : minimum.to_i)
  end

  def casted_maximum
    maximum.blank? ? nil : (qtype_name == 'decimal' ? maximum : maximum.to_i)
  end

  def casted_minimum=(m)
    self.minimum = m
    self.minimum = casted_minimum
  end

  def casted_maximum=(m)
    self.maximum = m
    self.maximum = casted_maximum
  end

  def min_max_error_msg
    return nil unless minimum || maximum
    clauses = []
    clauses << I18n.t("question.maxmin.gt") + " " + (minstrictly ? "" : I18n.t("question.maxmin.or_eq") + " " ) + casted_minimum.to_s if minimum
    clauses << I18n.t("question.maxmin.lt") + " " + (maxstrictly ? "" : I18n.t("question.maxmin.or_eq") + " " ) + casted_maximum.to_s if maximum
    I18n.t("layout.must_be") + " " + clauses.join(" " + I18n.t("common.and") + " ")
  end

  # returns sorted list of form ids related to this form
  def form_ids
    forms.collect{|f| f.id}.sort
  end

  # gets a comma separated list of all related forms names
  def form_names
    forms.map(&:name).join(', ')
  end

  def constraint_changed?
    %w(minimum maximum minstrictly maxstrictly).any? { |f| send("#{f}_changed?") }
  end

  # checks if any core fields (type, option set, constraints) changed
  def core_changed?
    qtype_name_changed? || option_set_id_changed? || constraint_changed?
  end

  # shortcut accessor
  def option_levels
    option_set.present? ? option_set.option_levels : []
  end

  # This should be able to be done by adding `order: :name` to the association, but that causes a cryptic SQL error
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

  def at_least_one_name
    errors.add(:base, :at_least_one_name) if name.blank?
  end

  def check_condition_integrity
    Condition.check_integrity_after_question_change(self)
  end
end
