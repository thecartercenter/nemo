class UserGroupsController < ApplicationController
  before_action :load_user_groups
  before_action :find_user_group, only: [:add_users, :remove_users]
  load_and_authorize_resource

  def index
    @add_mode = params[:add].present?
    @remove_mode = params[:remove].present?
    if params[:add].present?
      @mode_string = "add_to_group"
    elsif params[:remove].present?
      @mode_string = "remove_from_group"
    end
    render(partial: "group_select_modal") if request.xhr?
  end

  def edit
    render(partial: "edit_name")
  end

  def update
    @user_group.name = params[:name]
    if @user_group.save
      render json: { name: @user_group.name }
    else
      flash[:error] = @user_group.errors.full_messages.join(", ")
      head(422)
    end
  end

  def create
    @add_mode = params[:add].present?
    @user_group.name = params[:name]
    if @user_group.save
      render(partial: "index_table") if request.xhr?
    else
      flash[:error] = @user_group.errors.full_messages.join(", ")
      head(422)
    end
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
    head(:ok)
  end

  def remove_users
    users = load_users(params[:user_ids])
    @user_group.users = (@user_group.users - users)
    @user_group.save
    flash[:success] = I18n.t("user_group.remove_users_success", count: users.count, group: @user_group.name)
    flash.keep(:success)
    head(:ok)
  end

  def possible_groups
    @user_groups = @user_groups.name_matching(params[:q])
    render json: @user_groups
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
