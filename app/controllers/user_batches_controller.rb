# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserBatchesController < TabularImportsController
  skip_authorization_check only: :upload
  load_and_authorize_resource except: :upload
  skip_authorize_resource only: %i[template upload]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def tabular_class
    UserBatch
  end

  def tabular_type_symbol
    :user_import
  end

  def tabular_type_url
    users_url
  end

  def template
    authorize!(:create, UserBatch)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserBatch::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:file_import]
  end
end
