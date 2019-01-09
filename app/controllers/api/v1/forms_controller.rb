require 'will_paginate/array'
class API::V1::FormsController < API::V1::BaseController
  respond_to :json

  def index
    forms = current_mission.forms.where("access_level = 'public' OR access_level = 'protected' AND
      EXISTS (SELECT * FROM whitelistings WHERE whitelistable_id = forms.id AND user_id = ?)", @api_user.id).
      with_responses_counts.order(:name)
    paginate json: forms, each_serializer: API::V1::FormSerializer
  end

  def show
    @form = Form.find_by(id: params[:id])

    if @form.nil?
      render json: { errors: ["form_not_found"] }, status: 404

    elsif !@form.api_user_id_can_see?(@api_user.id)
      render json: { errors: ["access_denied"] }, status: 403

    else
      render json: @form, serializer: API::V1::FormSerializer
    end
  end
end
