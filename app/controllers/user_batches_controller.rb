# frozen_string_literal: true

# For importing users from CSV/spreadsheet.
class UserBatchesController < ApplicationController
  include OperationQueueable

  load_and_authorize_resource
  skip_authorize_resource only: [:template]

  # ensure a recent login for all actions
  before_action :require_recent_login

  def new
    render("form")
  end

  def create
    if @user_batch.valid?
      do_import
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

  def do_import
    stored_path = UploadSaver.new.save_file(@user_batch.file)
    operation.enqueue(nil, stored_path, @user_batch.class.to_s)
    prep_operation_queued_flash(:user_import)
    redirect_to(users_url)
  rescue StandardError => e
    Rails.logger.error(e)
    flash.now[:error] = I18n.t("activerecord.errors.models.user_batch.internal")
    render("form")
  end

  def operation
    Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: TabularImportOperationJob,
      details: t("operation.details.user_import", file: @user_batch.file.original_filename)
    )
  end

  def user_batch_params
    params.require(:user_batch).permit(:file) if params[:user_batch]
  end
end
