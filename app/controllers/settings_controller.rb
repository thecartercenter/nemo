class SettingsController < ApplicationController
  def index
    # load all settings
    @settings = Setting.load_and_create
  end
  
  def update_all
    @settings = Setting.find_and_update_all(params[:settings].values)
    # for each setting, update
    unless @settings.detect{|s| !s.valid?}
      flash[:success] = "Settings updated successfully."
      redirect_to(:action => :index)
    else
      flash[:error] = "Settings have errors. Please see below."
      render(:action => :index)
    end
  end
end
