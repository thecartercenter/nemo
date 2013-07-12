class OptionSet < ActiveRecord::Base
  include MissionBased, FormVersionable

  has_many(:option_settings, :dependent => :destroy, :autosave => true, :inverse_of => :option_set)
  has_many(:options, :through => :option_settings, :order => "option_settings.rank")
  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  
  validates(:name, :presence => true)
  validates_associated(:option_settings)
  validate(:at_least_one_option)
  validate(:name_unique_per_mission)
  
  before_validation(:ensure_ranks)
  before_save(:notify_form_versioning_policy_of_update)
  
  default_scope(order("name"))
  scope(:with_associations, includes(:questions, :options, {:questionings => :form}))
  
  self.per_page = 100
  
  def published?
    # check for any published questionings
    !questionings.detect{|qing| qing.published?}.nil?
  end
  
  # finds or initializes an option_setting for every option in the database for current mission (never meant to be saved)
  def all_option_settings(options)
    # make sure there is an associated answer object for each questioning in the form
    options.collect{|o| option_setting_for(o) || option_settings.new(:option_id => o.id, :included => false)}
  end
  
  def all_option_settings=(params)
    # create a bunch of temp objects, discarding any unchecked options
    submitted = params.values.collect{|p| p[:included] == '1' ? OptionSetting.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    option_settings.compare_by_element(submitted, Proc.new{|os| os.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        options.delete(orig.option)
      # if original is nil, add the new one to this option_set's array
      elsif orig.nil?
        option_settings << OptionSetting.new(:option => subd.option)
      end
    end
  end
    
  def option_setting_for(option)
    # get the matching option_setting
    option_setting_hash[option]
  end

  def option_setting_hash(options = {})
    @option_setting_hash = nil if options[:rebuild]
    @option_setting_hash ||= Hash[*option_settings.collect{|os| [os.option, os]}.flatten]
  end
  
  def as_json(options = {})
    Hash[*%w(id name).collect{|k| [k, self.send(k)]}.flatten]
  end
  
  # gets all forms to which this option set is linked (through questionings)
  def forms
    questionings.collect(&:form).uniq
  end
  
  def check_associations
    # make sure not associated with any questions
    raise DeletionError.new(:cant_delete_if_has_questions) unless questions.empty?
    
    # make sure not associated with any existing answers/choices
    option_settings.each{|os| os.no_answers_or_choices}
  end
  
  private
    # makes sure that the options in the set have sequential ranks starting at 1. 
    # if not, fixes them.
    def ensure_ranks
      # sort the option settings by existing rank and then re-assign to ensure sequentialness
      # if the options are already sorted this way, nothing will change
      # if a rank is null, we sort it to the end
      option_settings.sort_by{|o| o.rank || 10000000}.each_with_index{|o, idx| o.rank = idx + 1}
    end
    
    def at_least_one_option
      errors.add(:base, :at_least_one) if option_settings.empty?
    end
    
    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end
end
