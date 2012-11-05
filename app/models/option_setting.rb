class OptionSetting < ActiveRecord::Base
  belongs_to(:option, :inverse_of => :option_settings)
  belongs_to(:option_set, :inverse_of => :option_settings)
  
  before_destroy(:no_answers_or_choices)
  
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
  
  private
    def no_answers_or_choices
      if has_answers_or_choices?
        raise InvalidAssociationDeletionError.new(
          "You can't remove the option '#{option.name_eng}' because some responses are using it.")
      end
    end
end
