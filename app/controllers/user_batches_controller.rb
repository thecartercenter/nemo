class UserBatchesController < ApplicationController
  # special load technique for show
  before_filter :load_batch_from_session, :only => :show

  # authorization via cancan
  load_and_authorize_resource
  
  def new
  end
  
  def create
    begin
      @user_batch.create_users(current_mission)
      @success_msg = t("user_batch.success")
      render(:show)
    rescue ActiveRecord::RecordInvalid
      flash[:error] = $!.to_s
      render(:new)
    end
  end
  
  private
    def load_batch_from_session
      @user_batch = session[:new_user_batch]
    end
end
