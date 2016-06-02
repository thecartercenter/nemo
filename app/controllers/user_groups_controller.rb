class UserGroupsController < ApplicationController
  before_action :load_user_groups
  load_and_authorize_resource

  def index
    render(partial: "index_table") if request.xhr?
  end

  private

  def load_user_groups
    @user_groups = UserGroup.accessible_by(current_ability).order(:name)
  end
end
