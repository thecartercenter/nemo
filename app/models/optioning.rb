class Optioning < ActiveRecord::Base
  include MissionBased, Standardizable, Replicable

  belongs_to(:option, :inverse_of => :optionings)
  belongs_to(:option_set, :inverse_of => :optionings)
  
  before_create(:set_mission)
  before_destroy(:no_answers_or_choices)
  
  accepts_nested_attributes_for(:option)

  # replication options
  replicable :assocs => :option, :parent => :option_set

  # temp var used in the option_set form
  attr_writer :included
  
  def included
    # default to true
    defined?(@included) ? @included : true
  end
  
  # looks for answers and choices related to this option setting 
  def has_answers_or_choices?
    !option_set.questions.detect{|q| q.questionings.detect{|qing| qing.answers.detect{|a| a.option_id == option_id || a.choices.detect{|c| c.option_id == option_id}}}}.nil?
  end
  
  def no_answers_or_choices
    raise DeletionError.new(:cant_delete_if_has_response) if has_answers_or_choices?
  end
  
  def removable?
    !has_answers_or_choices?
  end

  def as_json(options = {})
    {:id => id, :option => option, :removable => removable?}
  end

  private

    # copy mission from option_set
    def set_mission
      Rails.logger.debug "SETTING MISSION TO #{option_set.try(:mission).inspect}"
      self.mission = option_set.try(:mission)
    end

end
