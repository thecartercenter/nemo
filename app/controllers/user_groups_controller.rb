class UserGroupsController < ApplicationController
  before_action :load_user_groups
  before_action :find_user_group, only: [:add_users]
  load_and_authorize_resource

  def index
    @add_mode = params[:add].present?
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
    @add_mode = params[:add].present?
    @user_group.name = params[:name]
    @user_group.save
    render(partial: "index_table") if request.xhr?
  end

  def destroy
    @user_group.destroy
    page_info = view_context.page_entries_info(load_user_groups, model: UserGroup)
    render json: { page_entries_info: page_info }
  end

  def add_users
    users = load_users(params[:user_ids])
    @user_group.users << (users - @user_group.users)
    @user_group.save
    flash[:success] = I18n.t("user_group.add_users_success", count: users.count, group: @user_group.name)
    flash.keep(:success)
    render nothing: true
  end

  private

  def load_user_groups
    @user_groups = UserGroup.accessible_by(current_ability).order(:name).paginate(page: 1, per_page: 500)
  end

  def find_user_group
    @user_group = UserGroup.accessible_by(current_ability).find(params[:user_group_id])
  end

  def load_users(user_ids)
    @user_groups = User.accessible_by(current_ability).includes(:assignments).where(id: user_ids, assignments: { mission: current_mission})
  end
end
