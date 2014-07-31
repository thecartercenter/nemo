require 'will_paginate/array'
class API::V1::FormsController < API::V1::BaseController
  respond_to :json

  def index
    if params[:mission_name].present?
      if @mission = Mission.where(:compact_name => params[:mission_name]).first
        forms = @mission.forms.where(access_level: 'public').order(:name)
        paginate json: (forms + protected_forms), each_serializer: API::V1::FormSerializer
      else
        render :text => 'INVALID_MISSION', :status => 404
      end
    end
  end

  def show
    @form = Form.find(params[:id])
    if @form.access_level == 'protected' && @form.api_user_id_can_see?(@api_user.id)
     @form = Form.includes(:questions).
             where(id: params[:id]).
             where("questions.access_level = 'inherit'").
             first
      #TODO: When we have budget refactor to use a scope for (public or nil) or make public access same as nil
    elsif @form.access_level != 'private'
      @form = Form.includes(:questions).
              where(id: params[:id]).
              where("questions.access_level = 'inherit'").
              first
    end
    render :json => @form.to_json(only: [:id, :name, :created_at, :updated_at],
                                  include: {questions: {methods: :name, only: :id}})
  rescue ActiveRecord::RecordNotFound
    render :json => [], :status => 404
  end

  private

  def protected_forms
    @mission.forms.joins(:whitelist_users).where(whitelists: {user_id: @api_user.id}).order(:name)
  end

end
