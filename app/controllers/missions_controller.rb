class MissionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource
  
  def index
  end
  
  def new
    render(:form)
  end
  
  def edit
    render(:form)
  end

  def create
    begin
      @mission.update_attributes!(params[:mission])
      flash[:success] = "Mission created successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end
  
  def update
    begin
      @mission.update_attributes!(params[:mission])
      flash[:success] = "Mission updated successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end

  def destroy
    begin
      @mission.destroy
      flash[:success] = "Mission deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
end
