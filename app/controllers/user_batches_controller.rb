class UserBatchesController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    prepare_and_render_form
  end

  def create
    if @user_batch.valid?
      begin
        uploaded = user_batch_params[:file]
        stored = private_upload_path(uploaded)
        FileUtils.mkdir_p(File.dirname(stored), mode: 0755)
        File.open(stored, 'wb') do |file|
          file.write(uploaded.read)
        end

        operation = Operation.new(
          job_class: UserImportOperationJob,
          description: t('operation.description.user_import_operation_job', file: uploaded.original_filename, mission_name: current_mission.name),
          creator: current_user)
        operation.begin!(current_mission, stored)

        flash[:notice] = t('user_batch.import_queued_html', url: operations_path).html_safe
        redirect_to(users_url)
      rescue => e
        Rails.logger.error(e)
        flash.now[:error] = I18n.t('activerecord.errors.models.user_batch.general')
        prepare_and_render_form
      end
    else
      flash.now[:error] = I18n.t('activerecord.errors.models.user_batch.general')
      prepare_and_render_form
    end
  end

  def example_spreadsheet
    authorize!(:create, UserBatch)

    @sheet_name = User.model_name.human(count: 0)
    @headers = %i{name phone phone2 email notes}.map do |field|
      User.human_attribute_name(field)
    end
  end

  private

    # prepares objects for and renders the form template
    def prepare_and_render_form
      render :form
    end

    def private_upload_path(file)
      file_name = "user_batch-#{SecureRandom.uuid}-#{file.original_filename}"
      Rails.root.join('tmp', 'uploads', file_name).to_s
    end

    def user_batch_params
      if params[:user_batch]
        params.require(:user_batch).permit(:file)
      end
    end
end
