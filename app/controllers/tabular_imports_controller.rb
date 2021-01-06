# frozen_string_literal: true

# For importing spreadsheets
class TabularImportsController < ApplicationController
  include OperationQueueable

  def upload
    authorize!(:create, tabular_class)
    saved_upload = SavedTabularUpload.new(file: params[:file])

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
    authorize!(:create, tabular_class)
    saved_upload = SavedUpload.find(params[:saved_upload_id])
    do_import(saved_upload)
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = I18n.t("errors.file_upload.file_missing")
    build_object
    render(:new)
  end

  private

  def tabular_type_symbol
    tabular_class.model_name.i18n_key
  end

  def do_import(saved_upload)
    operation(saved_upload).enqueue
    prep_operation_queued_flash(tabular_type_symbol)
    redirect_to(after_create_redirect_url)
  end

  def operation(saved_upload)
    Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: TabularImportOperationJob,
      details: t("operation.details.#{tabular_type_symbol}", file: saved_upload.file.original_filename),
      job_params: send("#{tabular_type_symbol}_params").to_h.symbolize_keys.merge(
        saved_upload_id: saved_upload.id,
        import_class: tabular_class.to_s
      )
    )
  end
end
