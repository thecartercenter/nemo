class UserBatchesController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource
  skip_authorize_resource only: [:template]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    render("form")
  end

  def create
    if @user_batch.valid?
      begin
        stored_path = UploadSaver.new.save_file(@user_batch.file)

        operation = current_user.operations.build(
          job_class: TabularImportOperationJob,
          details: t("operation.details.user_import_operation_job",
            file: @user_batch.file.original_filename,
            mission_name: current_mission.name))
        operation.begin!(current_mission, nil, stored_path, @user_batch.class.to_s)

        flash[:html_safe] = true
        flash[:notice] = t("import.queued_html", type: UserBatch.model_name.human, url: operations_path)
        redirect_to(users_url)
      rescue => e
        Rails.logger.error(e)
        flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.internal")
        render("form")
      end
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.general")
      render("form")
    end
  end

  def template
    authorize!(:create, UserBatch)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserBatch::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:user_batch]
  end
end
