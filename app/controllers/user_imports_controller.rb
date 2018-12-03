# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserImportsController < TabularImportsController
  include OperationQueueable
  skip_authorization_check only: :upload
  load_and_authorize_resource except: :upload
  skip_authorize_resource only: %i[template upload]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def tabular_class
    UserImport
  end

  def tabular_type_symbol
    :user_import
  end

  def after_create_redirect_url
    users_url
  end

  def template
    authorize!(:create, UserImport)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserImport::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def user_import_params
    params.require(:file_import).permit(:file).merge(mission: current_mission) if params[:file_import]
  end
end
