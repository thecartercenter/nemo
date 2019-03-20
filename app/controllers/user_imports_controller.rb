# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserImportsController < TabularImportsController
  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    authorize!(:create, UserImport)
    @user_import = UserImport.new(mission: current_mission)
  end

  def template
    authorize!(:create, UserImport)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserImport::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  protected

  def user_import_params
    {}
  end

  def tabular_class
    UserImport
  end

  def after_create_redirect_url
    users_url
  end
end
