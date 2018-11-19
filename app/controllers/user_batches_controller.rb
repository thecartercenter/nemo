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
    authorize!(:create, UserBatch)

    saved_upload = SavedUpload.create!(file: params[:file_import])

    # Json keys match hidden input names that contain the key in dropzone form.
    # See ELMO.Views.FileUploaderView for more info.
    render(json: {saved_upload_id: saved_upload.id})
  end

  def create
    saved_upload = SavedUpload.find(params[:saved_upload_id])
    do_import(saved_upload)
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = I18n.t("errors.file_upload.file_missing")
    render("form")
  end

  def template
    authorize!(:create, UserBatch)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserBatch::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def do_import(saved_upload)
    operation(saved_upload).enqueue
    prep_operation_queued_flash(:user_import)
    redirect_to(users_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.internal")
    render("form")
  end

  def operation(saved_upload)
    Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: TabularImportOperationJob,
      details: t("operation.details.user_import", file: saved_upload.file.original_filename),
      job_params: {
        saved_upload_id: saved_upload.id,
        import_class: @user_batch.class.to_s
      }
    )
  end

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:file_import]
  end
end
