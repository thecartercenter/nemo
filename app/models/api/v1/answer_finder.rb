class API::V1::AnswerFinder

  def self.for_one(params)
    return [] if self.form_with_permissions(params[:form_id]).blank?
    answers = Answer.includes(:response, :questioning).
                     where(responses: {form_id: params[:form_id]}).
                     where(form_items: {question_id: params[:question_id]}).
                     public_access
    self.filter(answers, params)
  end


  def self.for_all(params)
    form = self.form_with_permissions(params[:form_id])
    return [] if form.blank?
    self.filter(form.responses, params)
  end

  # empty array is returned if a user does not have access to see the form
  # TODO: maybe better name here?
  def self.form_with_permissions(form_id)
    @form = Form.where(id: form_id).includes(:responses, :whitelist_users).first
    if @form.access_level == 'public'
      return @form
    elsif @form.access_level == 'protected'
      return @form if @form.api_user_id_can_see?(@api_user.id)
    else
      return []  #private
    end

  end

  def self.filter(object, params = {})
    object = object.where("responses.created_at < ?", params[:created_before]) if params[:created_before]
    object = object.where("responses.created_at > ?", params[:created_after]) if params[:created_after]
    object
  end

end
