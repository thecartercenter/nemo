class QuestionsController < ApplicationController
  def choose
    @form = Form.find(params[:form_id])
    @title = "Adding Questions to Form: #{@form.name}"
    @questions = apply_filters(Question.not_in_form(@form))
    if @questions.empty?
      redirect_to(new_questioning_path(:form_id => @form.id))
    else
      render(:action => :index)
    end
  end
end
