# a question on a form
class Question < ApplicationRecord
  include MissionBased, Replication::Standardizable, Replication::Replicable, FormVersionable, Translatable

  acts_as_paranoid

  # Note that the maximum allowable length is 22 chars (1 letter plus 21 letters/numbers)
  # The user is told that the max is 20.
  # This is because we need to leave room for additional digits at the end during replication to maintain uniqueness.
  CODE_FORMAT = "[a-zA-Z][a-zA-Z0-9]{1,21}"
  API_ACCESS_LEVELS = %w(inherit private)

  belongs_to(:option_set, :inverse_of => :questions, :autosave => true)
  has_many(:questionings, :dependent => :destroy, :autosave => true, :inverse_of => :question)
  has_many(:answers, :through => :questionings)
  has_many(:referring_conditions, :through => :questionings)
  has_many(:forms, :through => :questionings)
  has_many(:calculations, class_name: 'Report::Calculation', foreign_key: 'question1_id', inverse_of: :question1)
  has_many(:taggings, :dependent => :destroy)
  has_many(:tags, :through => :taggings)

  accepts_nested_attributes_for :tags, reject_if: proc { |attributes| attributes[:name].blank? }

  before_validation(:normalize_fields)

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { calculations.each(&:question_destroyed) }

  validates(:code, :presence => true)
  validates(:code, :format => {:with => /\A#{CODE_FORMAT}\z/}, :if => Proc.new{|q| !q.code.blank?})
  validates(:qtype_name, :presence => true)
  validates(:option_set, :presence => true, :if => Proc.new{|q| q.qtype && q.has_options?})
  %w(minimum maximum).each do |field|
    validates(:"casted_#{field}", :numericality => { :allow_blank => true, :greater_than => -10_000_000, :less_than => 10_000_000 })
  end
  validate(:code_unique_per_mission)
  validate(:at_least_one_name)

  scope :by_code, -> { order('questions.code') }
  scope :with_code, ->(c) { where("LOWER(code) = ?", c.downcase) }
  scope :default_order, -> { by_code }
  scope :select_types, -> { where(:qtype_name => %w(select_one select_multiple)) }
  scope :with_forms, -> { includes(:forms) }
  scope :reportable, -> { where.not(qtype_name: %w(image annotated_image signature sketch audio video)) }
  scope :not_in_form, ->(form) { where("(questions.id NOT IN (
    SELECT question_id FROM form_items
      WHERE type = 'Questioning' AND form_id = ? AND deleted_at IS NULL))", form.id) }

  # Fetches association counts along with the questions.
  # Accounts for copies with standard questions.
  # - form_published_col contains true if any associated forms are published, false or nil otherwise
  scope(:with_assoc_counts, -> {
    select("questions.*").
    select("(
      SELECT COUNT(DISTINCT answers.id)
        FROM questions inner_questions
        LEFT OUTER JOIN form_items questionings
          ON questionings.deleted_at IS NULL AND questionings.question_id = inner_questions.id
            AND questionings.type = 'Questioning'
        LEFT OUTER JOIN forms ON forms.deleted_at IS NULL AND forms.id = questionings.form_id
        LEFT OUTER JOIN answers ON answers.deleted_at IS NULL AND answers.questioning_id = questionings.id
        WHERE inner_questions.deleted_at IS NULL AND inner_questions.id = questions.id
    ) AS answer_count_col").
    select("(
      SELECT COUNT(DISTINCT forms.id)
        FROM questions inner_questions
        LEFT OUTER JOIN form_items questionings
          ON questionings.deleted_at IS NULL AND questionings.question_id = inner_questions.id
            AND questionings.type = 'Questioning'
        LEFT OUTER JOIN forms ON forms.deleted_at IS NULL AND forms.id = questionings.form_id
        WHERE inner_questions.deleted_at IS NULL AND inner_questions.id = questions.id
    ) AS form_count_col").
    select("(
      SELECT BOOL_OR(DISTINCT forms.published)
        FROM questions inner_questions
        LEFT OUTER JOIN form_items questionings
          ON questionings.deleted_at IS NULL AND questionings.question_id = inner_questions.id
            AND questionings.type = 'Questioning'
        LEFT OUTER JOIN forms ON forms.deleted_at IS NULL AND forms.id = questionings.form_id
        WHERE inner_questions.deleted_at IS NULL AND inner_questions.id = questions.id
    ) AS form_published_col").
    select("(
      SELECT COUNT(DISTINCT copy_answers.id)
        FROM questions inner_questions
        LEFT OUTER JOIN form_items questionings
          ON questionings.deleted_at IS NULL AND questionings.question_id = inner_questions.id
            AND questionings.type = 'Questioning'
        LEFT OUTER JOIN forms ON forms.deleted_at IS NULL AND forms.id = questionings.form_id
        LEFT OUTER JOIN answers ON answers.deleted_at IS NULL AND answers.questioning_id = questionings.id
        LEFT OUTER JOIN questions copies ON questions.deleted_at IS NULL AND questions.is_standard = true
          AND questions.id = copies.original_id
        LEFT OUTER JOIN form_items copy_questionings ON copy_questionings.deleted_at IS NULL
          AND copy_questionings.question_id = copies.id AND copy_questionings.type = 'Questioning'
        LEFT OUTER JOIN forms copy_forms ON copy_forms.deleted_at IS NULL
          AND copy_forms.id = copy_questionings.form_id
        LEFT OUTER JOIN answers copy_answers ON copy_answers.deleted_at IS NULL
          AND copy_answers.questioning_id = copy_questionings.id
        WHERE inner_questions.deleted_at IS NULL AND inner_questions.id = questions.id
    ) AS copy_answer_count_col")
  })

  translates :name, :hint

  delegate :smsable?,
           :has_options?,
           :temporal?,
           :numeric?,
           :printable?,
           :multimedia?,
           :odk_tag,
           :odk_name,
           :to => :qtype

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
           :to => :option_set, :allow_nil => true

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
  # based on User.do_search
  def self.do_search(relation, query)
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # apply the needed associations
    relation = relation.joins(search.associations)

    # apply the conditions
    relation = relation.where(search.sql)
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

  def geographic?
    location_type? || qtype_name == "select_one" && option_set.geographic?
  end

  # DEPRECATED: this method should go away later
  def select_options
    (first_level_options || []).map{ |o| [o.name, o.id] }
  end

  # gets the number of forms which with this question is directly associated.
  # uses the form_count/std_form_count eager loaded fields if available
  def form_count
    respond_to?(:form_count_col) ? form_count_col : forms.count
  end

  # gets the number of answers to this question. uses an eager loaded col if available
  def answer_count
    if is_standard?
      respond_to?(:copy_answer_count_col) ? copy_answer_count_col : copies.inject(0){|sum,c| sum += c.answer_count}
    else
      respond_to?(:answer_count_col) ? answer_count_col : answers.count
    end
  end

  # determins if question has answers
  # uses the eager-loaded answer_count field if available
  def has_answers?
    answer_count > 0
  end

  # determines if the question appears on any published forms
  # uses the eager-loaded form_published_col field if available
  def published?
    is_standard? ? false : (respond_to?(:form_published_col) ? form_published_col == 1 : forms.any?(&:published?))
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

  # shortcut method for tests
  def qing_ids
    questionings.collect{|qing| qing.id}
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
    %w(minimum maximum minstrictly maxstrictly).any?{|f| send("#{f}_changed?")}
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

    def normalize_fields
      # clear whitespace from code
      self.code = code.strip

      normalize_constraint_values

      return true
    end

    # normalizes constraints based on question type
    def normalize_constraint_values
      # constraint should be nil/non-nil depending on qtype
      if qtype.try(:numeric?)
        # for numeric qtype, min/max can still be nil, and booleans should be nil if min/max are nil, else should be false
        self.minstrictly = false if !minimum.nil? && minstrictly.nil?
        self.maxstrictly = false if !maximum.nil? && maxstrictly.nil?
        self.minstrictly = nil if minimum.nil?
        self.maxstrictly = nil if maximum.nil?
      else
        # for non-numeric qtype, all constraint fields should be nil
        self.minimum = nil
        self.maximum = nil
        self.minstrictly = nil
        self.maxstrictly = nil
      end
    end

    def at_least_one_name
      errors.add(:base, :at_least_one_name) if name.blank?
    end
end
