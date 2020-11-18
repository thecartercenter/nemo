# frozen_string_literal: true

require "will_paginate/array"
class API::V1::FormsController < API::V1::BaseController
  respond_to :json

  def index
    forms = current_mission.forms.where("access_level = 'public' OR access_level = 'protected' AND
      EXISTS (SELECT * FROM whitelistings WHERE whitelistable_id = forms.id AND user_id = ?)", @api_user.id)
      .with_responses_counts.order(:name)
    paginate(json: API::V1::FormSerializer.render_as_json(forms))
  end

  def show
    @form = Form.find_by(id: params[:id])

    if @form.nil?
      render(json: {errors: ["form_not_found"]}, status: :not_found)

    elsif !@form.api_user_id_can_see?(@api_user.id)
      render(json: {errors: ["access_denied"]}, status: :forbidden)

    else
      render(json: API::V1::FormSerializer.render_as_json(@form, view: :show))
    end
  end
end
