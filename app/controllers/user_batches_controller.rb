class UserBatchesController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def new
  end

  def create
    @user_batch.create_users(current_mission)
    if @user_batch.succeeded?
      flash.now[:success] = t('user_batch.success')
      render(:show)
    else
      flash.now[:error] = t('user_batch.error')
      render(:new)
    end
  end
end
