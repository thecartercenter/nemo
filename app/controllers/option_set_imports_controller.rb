# frozen_string_literal: true

# For importing OptionSets from CSV/spreadsheet.
class OptionSetImportsController < ApplicationController
  include OperationQueueable

  load_and_authorize_resource

  def new
    render("form")
  end

  def upload
    authorize!(:create, OptionSetImport)
    saved_upload = SavedTabularUpload.new(file: params[:file_import])
    if saved_upload.save
    # Json keys match hidden input names that contain the key in dropzone form.
    # See ELMO.Views.FileUploaderView for more info.
      render(json: {saved_upload_id: saved_upload.id})
    else
      msg = I18n.t("errors.file_upload.invalid_format")
      render(json: {errors: [msg]}, status: :unprocessable_entity)
    end
  end

  def create
    saved_upload = SavedUpload.find(params[:saved_upload_id])
    do_import(saved_upload)
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = I18n.t("errors.file_upload.file_missing")
    render("form")
  end

  def template
    # TODO: make template
    NotImplementedError
  end

  protected

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
      details: t("operation.details.option_set_import", name: saved_upload.file.original_filename),
      job_params: {
        name: @option_set_import.name,
        saved_upload_id: saved_upload.id,
        import_class: @option_set_import.class.to_s
      }
    )
  end
end
