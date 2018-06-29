class API::V1::BaseController < ApplicationController
  skip_authorization_check  #for now at least

  rescue_from Exception, with: :handle_error

  before_action :authenticate

  serialization_scope :view_context

  protected

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, options|
      @api_user = User.find_by_api_key(token)
    end
  end

  protected

  def request_http_token_authentication(realm = "Application", message = nil)
    self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
    render json: { errors: ["invalid_api_token"] }, status: :unauthorized
  end

  private

  # Handles errors to give nice JSON response
  def handle_error(exception, options = {})
    if exception.is_a?(ActiveRecord::RecordNotFound)
      render json: { errors: [exception.message.downcase.gsub(" ", "_")] }
    else
      raise exception
    end
  end

  def find_form
    if params[:form_id].blank?
      render json: { errors: ["form_id_required"] }, status: 422
    else
      @form = Form.where(id: params[:form_id]).includes(:whitelistings).first

      if @form.nil?
        return render json: { errors: ["form_not_found"] }, status: 404
      elsif !@form.api_user_id_can_see?(@api_user.id)
        return render json: { errors: ["access_denied"] }, status: 403
      end
    end
  end

  # Applies created_before/after filter to Answers or Responses
  def add_date_filter(objects)
    if params[:created_after].present?
      objects = objects.created_after(Time.zone.parse(params[:created_after]))
    end
    if params[:created_before].present?
      objects = objects.created_before(Time.zone.parse(params[:created_before]))
    end
    objects
  end
end
