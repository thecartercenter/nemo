class UserBatchesController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def new
  end

  def create
    @user_batch.create_users(current_mission)
    if @user_batch.succeeded?
      @success_msg = t('user_batch.success')
      render(:show)
    else
      @error_msg = t('user_batch.error')
      render(:new)
    end
  end
end
