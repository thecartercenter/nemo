# frozen_string_literal: true

class API::V1::BaseController < ApplicationController
  skip_authorization_check # for now at least

  rescue_from Exception, with: :handle_error

  before_action :authenticate

  protected

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, _options|
      @api_user = User.find_by(api_key: token)
    end
  end

  def request_http_token_authentication(realm = "Application", _message = nil)
    headers["WWW-Authenticate"] = %(Token realm="#{realm.delete('"')}")
    render(json: {errors: ["invalid_api_token"]}, status: :unauthorized)
  end

  private

  # Handles errors to give nice JSON response
  def handle_error(exception, _options = {})
    if exception.is_a?(ActiveRecord::RecordNotFound)
      render(json: {errors: [exception.message.downcase.tr(" ", "_")]})
    else
      raise exception
    end
  end

  def find_form
    if params[:form_id].blank?
      render(json: {errors: ["form_id_required"]}, status: :unprocessable_entity)
    else
      @form = Form.where(id: params[:form_id]).includes(:whitelistings).first

      if @form.nil?
        render(json: {errors: ["form_not_found"]}, status: :not_found)
      elsif !@form.api_user_id_can_see?(@api_user.id)
        render(json: {errors: ["access_denied"]}, status: :forbidden)
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
