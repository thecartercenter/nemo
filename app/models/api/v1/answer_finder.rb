class API::V1::AnswerFinder

  def self.for_one(params)
    return [] if self.form_with_permissions(params[:form_id]).blank?
    answers = Answer.includes(:response, :questionable).
                     where(responses: {form_id: params[:form_id]}).
                     where(questionable_id: params[:question_id]).
                     public_access
    self.filter(answers, params)
  end

  def self.for_all(params)
    form = self.form_with_permissions(params[:form_id])
    return [] if form.blank?
    self.filter(form.responses, params)
  end

  def self.form_with_permissions(form_id)
    # This allows for protected and public forms
    # TODO: check for protected form allowed by api user  
    Form.includes(:responses).where(:id => form_id).where("access_level != ?", AccessLevel::PRIVATE).first
  end
  
  def self.filter(object, params = {})
    object = object.where("responses.created_at < ?", params[:created_before]) if params[:created_before]
    object = object.where("responses.created_at > ?", params[:created_after]) if params[:created_after]
    object
  end

end
