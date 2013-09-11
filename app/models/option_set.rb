class OptionSet < ActiveRecord::Base
  include MissionBased, Standardizable, Replicable


  has_many(:optionings, :order => "rank", :dependent => :destroy, :autosave => true, :inverse_of => :option_set)
  has_many(:options, :through => :optionings, :order => "optionings.rank")
  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  has_many(:report_option_set_choices, :inverse_of => :option_set, :class_name => "Report::OptionSetChoice")
  
  validates(:name, :presence => true)
  validate(:at_least_one_option)
  validate(:name_unique_per_mission)
  
  before_validation(:ensure_ranks)
  before_validation(:ensure_option_missions)
  
  scope(:with_associations, includes(:questions, {:optionings => :option}, {:questionings => :form}))

  scope(:by_name, order('option_sets.name'))
  scope(:with_assoc_counts_and_published, lambda { |mission|
    select('option_sets.*, counts.answer_count, counts.choice_count, COUNT(questions.id) AS question_count, MAX(forms.published) AS form_published').
    joins(%{
      LEFT OUTER JOIN questions ON questions.option_set_id = option_sets.id 
      LEFT OUTER JOIN questionings ON questionings.question_id = questions.id 
      LEFT OUTER JOIN forms ON forms.id = questionings.form_id
      LEFT OUTER JOIN (
        SELECT option_sets.id AS count_os_id, COUNT(answers.id) AS answer_count, COUNT(choices.id) AS choice_count
          FROM option_sets 
            LEFT OUTER JOIN optionings ON optionings.option_set_id = option_sets.id 
            LEFT OUTER JOIN answers ON answers.option_id = optionings.option_id 
            LEFT OUTER JOIN choices ON choices.option_id = optionings.option_id 
          WHERE option_sets.mission_id = #{mission.id}
          GROUP BY option_sets.id
      ) AS counts ON counts.count_os_id = option_sets.id
    }).group('option_sets.id')})
  
  accepts_nested_attributes_for(:optionings, :allow_destroy => true)
  
  self.per_page = 100

  # replication options
  replicable :assocs => :optionings, :parent => :question, :uniqueness => {:field => :name, :style => :sep_words}
  
  # checks if this option set appears in any published questionings
  def published?
    questionings.any?(&:published?)
  end

  # checks if this option set appears in any smsable questionings
  def form_smsable?
    questionings.any?(&:form_smsable?)
  end

  # checks if this option set is used in at least one question
  # uses the special 'question_count' field if it was loaded, else uses the questionings assoc
  def has_questions?
    respond_to?(:question_count) ? question_count > 0 : !questionings.empty?
  end

  # checks if this option set has any answers/choices
  # uses methods from special eager loaded scope if they are available
  def has_answers?
    # check for answers
    return true if (respond_to?(:answer_count) ? answer_count > 0 : options.any?(&:has_answers?))

    # check for choices
    return true if (respond_to?(:choice_count) ? choice_count > 0 : options.any?(&:has_choices?))

    # if we get here, false
    false
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

  # gets a comma separated list of all related forms names
  def form_names
    forms.map(&:name).join(', ')
  end
  
  def check_associations
    # make sure not associated with any questions
    raise DeletionError.new(:cant_delete_if_has_questions) unless questions.empty?
    
    # don't need to check if associated with any existing answers/choices
    # since questions can't be deleted if there are existing responses, so the first check above is sufficient
  end
  
  # checks if any of the option ranks have changed since last save
  def ranks_changed?
    optionings.map(&:rank_was) != optionings.map(&:rank)
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
end
