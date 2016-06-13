class UserGroupsController < ApplicationController
  before_action :load_user_groups
  load_and_authorize_resource

  def index
    render(partial: "index_table") if request.xhr?
  end

  def edit
    render(partial: "edit_name")
  end

  def update
    @user_group.name = params[:name]
    @user_group.save
    render json: { name: @user_group.name }
  end

  def create
    @user_group.name = params[:name]
    @user_group.save
    render(partial: "index_table") if request.xhr?
  end

  def destroy
    @user_group.destroy
    page_info = view_context.page_entries_info(load_user_groups, model: UserGroup)
    render json: { page_entries_info: page_info }
  end

  private

  def load_user_groups
    @user_groups = UserGroup.accessible_by(current_ability).order(:name).paginate(page: 1, per_page: 500)
  end
end
