class UserBatchesController < ApplicationController
  include UploadProcessable

  # authorization via cancan
  load_and_authorize_resource
  skip_authorize_resource only: [:example_spreadsheet]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    render("form")
  end

  def create
    if @user_batch.valid?
      begin
        stored_path = store_uploaded_file(@user_batch.file)

        operation = current_user.operations.build(
          job_class: TabularImportOperationJob,
          description: t("operation.description.user_import_operation_job",
            file: @user_batch.file.original_filename,
            mission_name: current_mission.name))
        operation.begin!(current_mission, nil, stored_path, @user_batch.class.to_s)

        flash[:notice] = t("import.queued_html", type: UserBatch.model_name.human, url: operations_path).html_safe
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

  def example_spreadsheet
    authorize!(:create, UserBatch)

    @sheet_name = User.model_name.human(count: 0)
    @headers = %i{login name phone phone2 email birth_year gender nationality notes}.map do |field|
      User.human_attribute_name(field)
    end
  end

  private

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:user_batch]
  end
end
