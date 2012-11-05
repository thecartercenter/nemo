class MissionsController < ApplicationController
  def index
    @missions = Mission.all
  end
  
  def new
    @mission = Mission.new
    render(:form)
  end
  
  def edit
    @mission = Mission.find(params[:id])
    render(:form)
  end

  def destroy
    begin
      (@mission = Mission.find(params[:id])).destroy
      flash[:success] = "Mission deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  
  def create
    begin
      (@mission = Mission.new(params[:mission])).save!
      flash[:success] = "Mission created successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end
  
  def update
    begin
      (@mission = Mission.find(params[:id])).update_attributes!(params[:mission])
      flash[:success] = "Mission updated successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end
end
