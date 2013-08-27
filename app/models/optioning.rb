class Optioning < ActiveRecord::Base
  include FormVersionable, Standardizable, Replicable

  belongs_to(:option, :inverse_of => :optionings)
  belongs_to(:option_set, :inverse_of => :optionings)
  
  before_destroy(:no_answers_or_choices)
  after_create(:notify_form_versioning_policy_of_create)
  after_destroy(:notify_form_versioning_policy_of_destroy)
  
  accepts_nested_attributes_for(:option)

  # replication options
  replicable :assocs => [:option, :one]

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
end
