# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserBatchesController < ApplicationController
  skip_authorization_check only: :upload
  load_and_authorize_resource except: :upload
  skip_authorize_resource only: [:template, :upload]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    render("form")
  end

  def upload
    temp_file_path = UploadSaver.new.save_file(params[:userbatch])
    render(json: {tempFilePath: temp_file_path})
    # puts "UPLOAD ENDPOINT"
    # if @user_batch.valid?
    #   (@user_batch.file)
    #
    #  else
    #   flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.general")
    #   render("form")
    # end
  end

  def create
    #if #temp upload path valid
      do_import
    # else
    #   flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.general")
    #   render("form")
    # end
  end

  def template
    authorize!(:create, UserBatch)
    @sheet_name = User.model_name.human(count: 0)
    @headers = UserBatch::EXPECTED_HEADERS.map { |f| User.human_attribute_name(f) }
  end

  private

  def do_import
    # parse temp_upload_path from params
    operation.begin!(nil, temp_file_path, @user_batch.class.to_s)
    flash[:html_safe] = true
    flash[:notice] = t("import.queued_html", type: UserBatch.model_name.human, url: operations_path)
    redirect_to(users_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.internal")
    render("form")
  end

  def operation
    Operation.new(
      creator: current_user,
      job_class: TabularImportOperationJob,
      mission: current_mission,
      details: t("operation.details.user_import_operation_job",
        file: @user_batch.file.original_filename,
        mission_name: current_mission&.name)
    )
  end

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:user_batch]
  end
end
