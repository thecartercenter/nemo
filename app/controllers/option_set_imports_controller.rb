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
    original_file_name = params[:file_import].original_filename
    if [".csv", ".xlsx"].include? File.extname(original_file_name)
      temp_file_path = UploadSaver.new.save_file(params[:file_import])
      # Json keys match hidden input names that contain the key in dropzone form.
      # See ELMO.Views.FileUploaderView for more info.
      render(json: {temp_file_path: temp_file_path, original_filename: original_file_name})
    else
      msg = I18n.t("errors.file_upload.invalid_format")
      render(json: {errors: [msg]}, status: :unprocessable_entity)
    end
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
    # TODO: make template
    NotImplementedError
  end

  protected

  def do_import(temp_file_path, original_filename)
    operation(temp_file_path, original_filename).enqueue
    prep_operation_queued_flash(:option_set_import)
    redirect_to(option_sets_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.option_set_import.internal")
    render("form")
  end

  def operation(temp_file_path, original_filename)
    Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: TabularImportOperationJob,
      details: t("operation.details.option_set_import", name: original_filename),
      job_params: {
        name: original_filename,
        upload_path: temp_file_path,
        import_class: @option_set_import.class.to_s
      }
    )
  end

  # def option_set_import_params
  #   params.require([:original_file_name, :temp_file_path] ) do |whitelisted|
  #     #whitelisted[:mission_id] = current_mission.id
  #   end
  # end
end
