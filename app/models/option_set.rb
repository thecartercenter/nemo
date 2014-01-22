class OptionSet < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable, OptioningParentable

  # this needs to be up here or it will run too late
  before_destroy(:check_associations)

  # this association produces ALL optionings regardless of level. should only be used when quick access to the full set of optionings is
  # needed. note that if this and the normal optionings association are both used, there will be two separate sets of models in play.
  # note that dependent => destroy and autosave are not turned on here.
  has_many(:all_optionings, :class_name => 'Optioning', :order => 'optionings.parent_id, optionings.rank', :inverse_of => :option_set)

  # this association produces only the direct children of this option_set (the top-level options).
  has_many(:optionings, :order => "rank", :conditions => 'optionings.parent_id IS NULL',
    :dependent => :destroy, :autosave => true, :inverse_of => :option_set)

  # returns ONLY the first-level options for this option set, sorted by rank
  has_many(:options, :through => :optionings, :order => "optionings.rank")

  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  has_many(:option_levels, :dependent => :destroy, :autosave => true, :inverse_of => :option_set)

  validates(:name, :presence => true)
  validate(:at_least_one_option)
  validate(:name_unique_per_mission)
  validate(:multi_level_option_sets_must_have_option_levels)

  before_validation(:normalize_fields)
  before_validation(:ensure_children_ranks)
  before_validation(:ensure_option_level_ranks)

  scope(:with_associations, includes(:questions, {:optionings => :option}, {:questionings => :form}))

  scope(:by_name, order('option_sets.name'))
  scope(:default_order, by_name)
  scope(:with_assoc_counts_and_published, lambda { |mission|
    select(%{
      option_sets.*,
      COUNT(DISTINCT answers.id) AS answer_count_col,
      COUNT(DISTINCT questionables.id) AS question_count_col,
      MAX(forms.published) AS published_col,
      COUNT(DISTINCT copy_answers.id) AS copy_answer_count_col,
      COUNT(DISTINCT copy_questions.id) AS copy_question_count_col,
      MAX(copy_forms.published) AS copy_published_col
    }).
    joins(%{
      LEFT OUTER JOIN questionables ON questionables.option_set_id = option_sets.id AND questionables.type = 'Question'
      LEFT OUTER JOIN questionings ON questionings.question_id = questionables.id
      LEFT OUTER JOIN forms ON forms.id = questionings.form_id
      LEFT OUTER JOIN answers ON answers.questioning_id = questionings.id
      LEFT OUTER JOIN option_sets copies ON option_sets.is_standard = 1 AND copies.standard_id = option_sets.id
      LEFT OUTER JOIN questionables copy_questions ON copy_questions.option_set_id = copies.id AND copy_questions.type = 'Question'
      LEFT OUTER JOIN questionings copy_questionings ON copy_questionings.question_id = copy_questions.id
      LEFT OUTER JOIN forms copy_forms ON copy_forms.id = copy_questionings.form_id
      LEFT OUTER JOIN answers copy_answers ON copy_answers.questioning_id = copy_questionings.id
    }).group('option_sets.id')})

  accepts_nested_attributes_for(:optionings, :allow_destroy => true)

  # replication options
  replicable :child_assocs => :optionings, :parent_assoc => :question, :uniqueness => {:field => :name, :style => :sep_words}

  # remove heirarch of objects
  def self.terminate_sub_relationships(option_sets_ids)
    Optioning.where(option_set_id: option_sets_ids).delete_all
  end

  # checks if this option set appears in any smsable questionings
  def form_smsable?
    questionings.any?(&:form_smsable?)
  end

  # checks if this option set appears in any published questionings
  # uses eager loaded field if available
  def published?
    if is_standard?
      respond_to?(:copy_published_col) ? copy_published_col == 1 : copies.any?{|c| c.questionings.any?(&:published?)}
    else
      respond_to?(:published_col) ? published_col == 1 : questionings.any?(&:published?)
    end
  end

  # checks if this option set is used in at least one question or if any copies are used in at least one question
  def has_questions?
    ttl_question_count > 0
  end

  # gets total number of questions with which this option set is associated
  # in the case of a std option set, this includes non-standard questions that use copies of this option set
  def ttl_question_count
    question_count + copy_question_count
  end

  # gets number of questions in which this option set is directly used
  def question_count
    respond_to?(:question_count_col) ? question_count_col || 0 : questions.count
  end

  # gets number of questions by which a copy of this option set is used
  def copy_question_count
    if is_standard?
      respond_to?(:copy_question_count_col) ? copy_question_count_col || 0 : copies.inject(0){|sum, c| sum += c.question_count}
    else
      0
    end
  end

  # checks if this option set has any answers (that is, answers to questions that use this option set)
  # or in the case of a standard option set, answers to questions that use copies of this option set
  # uses method from special eager loaded scope if available
  def has_answers?
    if is_standard?
      respond_to?(:copy_answer_count_col) ? (copy_answer_count_col || 0) > 0 : copies.any?{|c| c.questionings.any?(&:has_answers?)}
    else
      respond_to?(:answer_count_col) ? (answer_count_col || 0) > 0 : questionings.any?(&:has_answers?)
    end
  end

  # gets the number of answers to questions that use this option set
  # or in the case of a standard option set, answers to questions that use copies of this option set
  # uses method from special eager loaded scope if available
  def answer_count
    if is_standard?
      respond_to?(:copy_answer_count_col) ? copy_answer_count_col || 0 : copies.inject?(0){|sum, c| sum += c.answer_count}
    else
      respond_to?(:answer_count_col) ? answer_count_col || 0 : questionings.inject(0){|sum, q| sum += q.answers.count}
    end
  end

  # gets all forms to which this option set is linked (through questionings)
  def forms
    questionings.collect(&:form).uniq
  end

  # gets a comma separated list of all related forms' names
  def form_names
    forms.map(&:name).join(', ')
  end

  # gets a comma separated list of all related questions' codes
  def question_codes
    questions.map(&:code).join(', ')
  end

  # checks if any core fields (currently only name) changed
  def core_changed?
    name_changed?
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      {:optionings => optionings.as_json(:for_option_set_form => true)}
    else
      super(options)
    end
  end

  # returns a string representation, including multilevel options, for the default locale.
  def to_s
    s = "Name: #{name}\nOptions:\n"
    s += optionings.map(&:to_s_indented).join
  end

  private

    # makes sure that the set's option_levels have sequential ranks starting at 1.
    def ensure_option_level_ranks
      option_levels.ensure_contiguous_ranks
    end

    def check_associations
      # make sure not associated with any questions
      raise DeletionError.new(:cant_delete_if_has_questions) if has_questions?

      # make sure not associated with any answers
      raise DeletionError.new(:cant_delete_if_has_answers) if has_answers?
    end

    def at_least_one_option
      # this checks only the first level options, which is sufficient
      errors.add(:base, :at_least_one) if optionings.reject{|a| a.marked_for_destruction?}.empty?
    end

    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end

    def normalize_fields
      self.name = name.strip
      return true
    end

    def multi_level_option_sets_must_have_option_levels
      errors.add(:base, "Multi-level OptionSets must have at least one OptionLevel") if multi_level? && option_levels.empty?
    end
end
