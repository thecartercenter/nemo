# frozen_string_literal: true

# For importing Users from spreadsheet.
class UserImportsController < TabularImportsController
  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    authorize!(:create, UserImport)
    build_object
  end

  def template
    authorize!(:create, UserImport)
    @headers = UserImport::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
    respond_to do |format|
      format.csv do
        render(csv: UserFacingCSV.generate { |csv| csv << @headers })
      end
    end
  end

  protected

  def build_object
    @user_import = UserImport.new(mission: current_mission)
  end

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
