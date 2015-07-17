class OptionSetImportsController < ApplicationController
  include UploadProcessable

  load_and_authorize_resource

  def new
    render('form')
  end

  def create
    if @option_set_import.valid?
      begin
        stored_path = store_uploaded_file(@option_set_import.file)

        operation = current_user.operations.build(
          job_class: OptionSetImportOperationJob,
          description: t('operation.description.option_set_import_operation_job', name: @option_set_import.name, mission_name: current_mission.name))
        operation.begin!(@option_set_import.mission, @option_set_import.name, stored_path)

        flash[:notice] = t('import.queued_html', type: OptionSet.model_name.human, url: operations_path).html_safe
        redirect_to(option_sets_url)
      rescue => e
        Rails.logger.error(e)
        flash.now[:error] = I18n.t('activerecord.errors.models.option_set_import.internal')
        render('form')
      end
    else
      flash.now[:error] = I18n.t('activerecord.errors.models.option_set_import.general')
      render('form')
    end
  end

  def example_spreadsheet
    # TODO: example spreadsheet
    NotImplementedError
  end

  protected

    def option_set_import_params
      params.require(:option_set_import).permit(:name, :file) do |whitelisted|
        whitelisted[:mission_id] = current_mission.id
      end
    end
end
