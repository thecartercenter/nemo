# frozen_string_literal: true

# For importing OptionSets from CSV/spreadsheet.
class OptionSetImportsController < ApplicationController
  include OperationQueueable

  load_and_authorize_resource

  def new
    render("form")
  end

  def create
    if @option_set_import.valid?
      do_import
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.option_set_import.general")
      render("form")
    end
  end

  def template
    # TODO: make template
    NotImplementedError
  end

  protected

  def do_import
    saved_upload = SavedUpload.create!(file: @option_set_import.file)
    operation(saved_upload).enqueue
    prep_operation_queued_flash(:option_set_import)
    redirect_to(option_sets_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.option_set_import.internal")
    render("form")
  end

  def operation(saved_upload)
    Operation.new(
      creator: current_user,
      job_class: TabularImportOperationJob,
      mission: current_mission,
      details: t("operation.details.option_set_import", name: @option_set_import.name),
      job_params: {
        name: @option_set_import.name,
        saved_upload_id: saved_upload.id,
        import_class: @option_set_import.class.to_s
      }
    )
  end

  def option_set_import_params
    params.require(:option_set_import).permit(:name, :file) do |whitelisted|
      whitelisted[:mission_id] = current_mission.id
    end
  end
end
