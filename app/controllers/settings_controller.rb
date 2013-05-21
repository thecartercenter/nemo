class SettingsController < ApplicationController
  # no authorization up here because we do it manually because Setting is atypical
  
  def index
    # load setting for current mission (create with defaults if doesn't exist)
    @setting = Setting.find_or_create(current_mission)
    
    # do authorization check
    authorize!(:update, @setting)
    
    prepare_and_render_form
  end
  
  def update
    begin
      # find the setting and authorize
      @setting = Setting.find(params[:id])
      authorize!(:update, @setting)
      
      @setting.update_attributes!(params[:setting])
      
      # copy the updated settings to the config
      @setting.copy_to_config
      
      flash[:success] = "Settings updated successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      prepare_and_render_form
    end
  end
  
  private
    # prepares objects and renders the form template (which in this case is really the index template)
    def prepare_and_render_form
      # load options for sms adapter dropdown
      @adapter_options = Sms::Adapters::Factory::VALID_ADAPTERS
      
      # render the template
      render(:index)
    end
end
