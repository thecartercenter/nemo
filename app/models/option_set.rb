class OptionSet < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable

  # this needs to be up here or it will run too late
  before_destroy(:check_associations)

  has_many(:optionings, :order => "rank", :dependent => :destroy, :autosave => true, :inverse_of => :option_set)
  has_many(:options, :through => :optionings, :order => "optionings.rank")
  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  has_many(:report_option_set_choices, :inverse_of => :option_set, :class_name => "Report::OptionSetChoice")

  validates(:name, :presence => true)
  validate(:at_least_one_option)
  validate(:name_unique_per_mission)

  before_validation(:normalize_fields)
  before_validation(:ensure_ranks)
  before_validation(:ensure_option_missions)

  scope(:with_associations, includes(:questions, {:optionings => :option}, {:questionings => :form}))

  scope(:by_name, order('option_sets.name'))
  scope(:default_order, by_name)
  scope(:with_assoc_counts_and_published, lambda { |mission|
    select(%{
      option_sets.*,
      COUNT(DISTINCT answers.id) AS answer_count_col,
      COUNT(DISTINCT questions.id) AS question_count_col,
      MAX(forms.published) AS published_col,
      COUNT(DISTINCT copy_answers.id) AS copy_answer_count_col,
      COUNT(DISTINCT copy_questions.id) AS copy_question_count_col,
      MAX(copy_forms.published) AS copy_published_col
    }).
    joins(%{
      LEFT OUTER JOIN questions ON questions.option_set_id = option_sets.id
      LEFT OUTER JOIN questionings ON questionings.question_id = questions.id
      LEFT OUTER JOIN forms ON forms.id = questionings.form_id
      LEFT OUTER JOIN answers ON answers.questioning_id = questionings.id
      LEFT OUTER JOIN option_sets copies ON option_sets.is_standard = 1 AND copies.standard_id = option_sets.id
      LEFT OUTER JOIN questions copy_questions ON copy_questions.option_set_id = copies.id
      LEFT OUTER JOIN questionings copy_questionings ON copy_questionings.question_id = copy_questions.id
      LEFT OUTER JOIN forms copy_forms ON copy_forms.id = copy_questionings.form_id
      LEFT OUTER JOIN answers copy_answers ON copy_answers.questioning_id = copy_questionings.id
    }).group('option_sets.id')})

  accepts_nested_attributes_for(:optionings, :allow_destroy => true)

  self.per_page = 100

  # replication options
  replicable :child_assocs => :optionings, :parent_assoc => :question, :uniqueness => {:field => :name, :style => :sep_words}

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

  # finds or initializes an optioning for every option in the database for current mission (never meant to be saved)
  def all_optionings(options)
    # make sure there is an associated answer object for each questioning in the form
    options.collect{|o| optioning_for(o) || optionings.new(:option_id => o.id, :included => false)}
  end

  def all_optionings=(params)
    # create a bunch of temp objects, discarding any unchecked options
    submitted = params.values.collect{|p| p[:included] == '1' ? Optioning.new(p) : nil}.compact

    # copy new choices into old objects, creating or deleting if necessary
    optionings.compare_by_element(submitted, Proc.new{|os| os.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        options.delete(orig.option)
      # if original is nil, add the new one to this option_set's array
      elsif orig.nil?
        optionings << Optioning.new(:option => subd.option)
      end
    end
  end

  def optioning_for(option)
    # get the matching optioning
    optioning_hash[option]
  end

  def optioning_hash(options = {})
    @optioning_hash = nil if options[:rebuild]
    @optioning_hash ||= Hash[*optionings.collect{|os| [os.option, os]}.flatten]
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

  # checks if any of the option ranks have changed since last save
  def ranks_changed?
    optionings.map(&:rank_was) != optionings.map(&:rank)
  end

  # checks if any core fields (currently only name) changed
  def core_changed?
    name_changed?
  end

  # checks if any options have been added since last save
  def options_added?
    optionings.any?(&:new_record?)
  end

  # checks if any options have been removed since last save
  # relies on the the marked_for_destruction field since this method is used by the controller
  def options_removed?
    optionings.any?(&:marked_for_destruction?)
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      {:optionings => optionings.as_json(:for_option_set_form => true)}
    else
      super(options)
    end
  end

  # Remove Heirarch of Objects
  def self.terminate_sub_relationships(option_sets)
     Optioning.where(option_set_id: option_sets).delete_all
  end

  private
    # makes sure that the options in the set have sequential ranks starting at 1.
    # if not, fixes them.
    def ensure_ranks
      # sort the option settings by existing rank and then re-assign to ensure sequentialness
      # if the options are already sorted this way, nothing will change
      # if a rank is null, we sort it to the end
      optionings.sort_by{|o| o.rank || 10000000}.each_with_index{|o, idx| o.rank = idx + 1}
    end

    def check_associations
      # make sure not associated with any questions
      raise DeletionError.new(:cant_delete_if_has_questions) if has_questions?

      # make sure not associated with any answers
      raise DeletionError.new(:cant_delete_if_has_answers) if has_answers?
    end

    def at_least_one_option
      errors.add(:base, :at_least_one) if optionings.reject{|a| a.marked_for_destruction?}.empty?
    end

    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end

    # ensures mission is set on all options
    def ensure_option_missions
      # go in through optionings association in case these are newly created options via nested attribs
      optionings.each{|oing| oing.option.mission_id ||= mission_id if oing.option}
    end

    def normalize_fields
      self.name = name.strip
      return true
    end

end
