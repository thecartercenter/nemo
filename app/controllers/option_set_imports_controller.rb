class OptionSetImportsController < ApplicationController
  load_and_authorize_resource

  def new
    render("form")
  end

  def create
    if @option_set_import.valid?
      begin
        stored_path = UploadSaver.new.save_file(@option_set_import.file)
        mission_name = current_mission.try(:name) || t("standard.standard")

        operation = current_user.operations.build(
          job_class: TabularImportOperationJob,
          details: t(
            "operation.details.option_set_import_operation_job",
            name: @option_set_import.name,
            mission_name: mission_name
          ),
          mission_id: current_mission.try(:id)
        )
        operation.begin!(
          @option_set_import.name,
          stored_path,
          @option_set_import.class.to_s
        )

        flash[:html_safe] = true
        flash[:notice] = t("import.queued_html", type: OptionSet.model_name.human, url: operations_path)
        redirect_to(option_sets_url)
      rescue => e
        Rails.logger.error(e)
        flash.now[:error] = I18n.t("activerecord.errors.models.option_set_import.internal")
        render("form")
      end
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

  def option_set_import_params
    params.require(:option_set_import).permit(:name, :file) do |whitelisted|
      whitelisted[:mission_id] = current_mission.id
    end
  end
end
