# methods required to setup a question for use in the new question form
module QuestionFormable
  extend ActiveSupport::Concern
  
  def init_qing(params)
    Questioning.new_with_question(current_mission, :form_id => params[:form_id])
  end
  
  def setup_qing_form_support_objs
    @option_sets = restrict(OptionSet)
    @question_types = restrict(QuestionType)
  end
end