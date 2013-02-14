class SettingsController < ApplicationController
  def index
    # load setting for current mission (create with defaults if doesn't exist)
    @setting = Setting.find_or_create(current_mission)
  end
  
  def update
    begin      
      (@setting = Setting.find(params[:id])).update_attributes!(params[:setting])
      
      # copy the updated settings to the config
      @setting.copy_to_config
      
      flash[:success] = "Settings updated successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:index)
    end
  end
end
