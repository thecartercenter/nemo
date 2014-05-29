class API::V1::AnswerFinder

  def self.for_one(params)
    return [] if self.form_with_permissions(params[:form_id]).blank?
    answers = Answer.includes(:response, :questionable).
                     where(responses: {form_id: params[:form_id]}).
                     where(questionable_id: params[:question_id]).
                     public_access
  end

  def self.for_all(params)
    form = self.form_with_permissions(params[:form_id])
    return [] if form.blank?
    form.responses
  end

  def self.form_with_permissions(form_id)
    # This allows for protected and public forms
    # TODO: check for protected form allowed by api user  
    Form.includes(:responses).where(:id => form_id).where("access_level != ?", AccessLevel::PRIVATE).first
  end

end
