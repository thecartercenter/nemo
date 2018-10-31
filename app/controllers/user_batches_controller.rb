# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserBatchesController < ApplicationController
  include OperationQueueable
  skip_authorization_check only: :upload
  load_and_authorize_resource except: :upload
  skip_authorize_resource only: %i[template upload]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    render("form")
  end

  def upload
    original_file_name = params[:userbatch].original_filename
    temp_file_path = UploadSaver.new.save_file(params[:userbatch])
    render(json: {tempFilePath: temp_file_path, originalFilename: original_file_name})
  rescue StandardError => e
    Rails.logger.error(e)
    render(errors: [I18n.t("activerecord.errors.models.user_batch.internal")])
  end

  def create
    temp_file_path = params[:temp_file_path]
    original_filename = params[:original_filename]
    if temp_file_path.present? && original_filename.present?
      do_import(temp_file_path, original_filename)
    else
      flash.now[:error] = I18n.t("errors.file_upload.file_missing")
      render("form")
    end
  end

  def template
    authorize!(:create, UserBatch)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserBatch::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def do_import(temp_file_path, original_filename)
    operation(temp_file_path, original_filename).enqueue
    prep_operation_queued_flash(:user_import)
    redirect_to(users_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.internal")
    render("form")
  end

  def operation(temp_file_path, original_filename)
    Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: TabularImportOperationJob,
      details: t("operation.details.user_import", file: original_filename),
      job_params: {
        upload_path: temp_file_path,
        import_class: @user_batch.class.to_s
      }
    )
  end

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:user_batch]
  end
end
