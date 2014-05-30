require 'will_paginate/array' 
class API::V1::FormsController < API::V1::BaseController
  respond_to :json

  def index
    if params[:mission_name].present?
      @mission = Mission.where(:compact_name => params[:mission_name]).first
      forms = @mission.forms.where(access_level: AccessLevel::PUBLIC).order(:name)
      paginate json: (forms + protected_forms), each_serializer: API::V1::FormSerializer
    end
  end

  def show
    @form = Form.includes(:questions).
                 where(id: params[:id]).
                 where(:questionables => {access_level: AccessLevel::PUBLIC}).
                 first
    render :json => @form.to_json(only: [:id, :name, :created_at, :updated_at],
                                  include: {questions: {methods: :name, only: :id}})
  end

  private

  def protected_forms
    @mission.forms.joins(:whitelist_users).where(whitelists: {user_id: @api_user.id}).order(:name) 
  end

end
