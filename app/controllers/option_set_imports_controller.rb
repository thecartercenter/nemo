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
    stored_path = UploadSaver.new.save_file(@option_set_import.file)
    # TODO: It seems odd to pass one set of attribs to Operation.new and then a second set to begin!
    # Maybe refactor to include these as an ephemeral job_params hash attribute in the constructor and
    # use it in begin!. then we can put the explanation for the split (serialization, etc.) in Operation.
    operation.begin!(@option_set_import.name, stored_path, @option_set_import.class.to_s)
    prep_operation_queued_flash(:option_set_import)
    redirect_to(option_sets_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.option_set_import.internal")
    render("form")
  end

  def operation
    Operation.new(
      creator: current_user,
      job_class: TabularImportOperationJob,
      mission: current_mission,
      details: t("operation.details.option_set_import", name: @option_set_import.name)
    )
  end

  def option_set_import_params
    params.require(:option_set_import).permit(:name, :file) do |whitelisted|
      whitelisted[:mission_id] = current_mission.id
    end
  end
end
