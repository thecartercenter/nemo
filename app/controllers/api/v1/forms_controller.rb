class API::V1::FormsController < API::V1::BaseController
  respond_to :json

  def index
    if params[:mission_name].present?
      @mission = Mission.where(:compact_name => params[:mission_name]).first
      forms = @mission.forms.where(access_level: AccessLevel::PUBLIC).order(:name)
      render :json => (forms + protected_forms).to_json(:only => [:id, :name, :responses_count, :created_at, :updated_at])

    end
  end

  def show
    @form = Form.includes(:questions).where(id: params[:id]).where(:questionables => {access_level: AccessLevel::PUBLIC}).first
    render :json => @form.to_json(only: [:id, :name, :created_at, :updated_at],
                                  include: {questions: {methods: :name, only: :id}})
  end

  private

  def protected_forms
    Form.joins(:whitelist_users).where(whitelists: {user_id: @api_user.id}).order(:name) 
  end
end
