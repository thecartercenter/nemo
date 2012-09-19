class UserBatchesController < ApplicationController
  def new
    @batch = UserBatch.new
  end
  
  def create
    @batch = UserBatch.new
    begin
      @batch.attributes = params[:user_batch]
      @batch.create_users(current_mission)
      flash[:success] = "Users created successfully."
      session[:new_user_batch] = @batch
      redirect_to(:action => :show, :id => 1)
    rescue ActiveRecord::RecordInvalid
      flash[:error] = $!.to_s
      render(:new)
    end
  end
  
  def show
    @batch = session[:new_user_batch]
  end
end
