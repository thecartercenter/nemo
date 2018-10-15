class SettingsController < ApplicationController
  # using a customize before_action to authorize resource here because Setting is atypical
  before_action :authorize_settings

  before_action :require_recent_login

  def index
    # setting is already loaded by application controller
    prepare_and_render_form
  end

  def update
    begin
      # Setting is already loaded in app/controllers/concerns/application_controller/settings.rb
      @setting.update_attributes!(setting_params)

      set_success_and_redirect(@setting)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = I18n.t('activerecord.errors.models.setting.general')
      prepare_and_render_form
    end
  end

  def regenerate_override_code
    @setting.generate_override_code!

    render json: { value: @setting.override_code }
  end

  def regenerate_incoming_sms_token
    @setting.regenerate_incoming_sms_token!

    render json: { value: @setting.incoming_sms_token }
  end

  def using_incoming_sms_token_message
    if params[:missionless].present?
      url = missionless_sms_submission_url(@setting.universal_sms_token, locale: nil, mission_name: nil, mode: nil)
    else
      url = mission_sms_submission_url(@setting.incoming_sms_token, locale: nil)
    end
    message = t('activerecord.hints.setting.using_incoming_sms_token_body', url: url)

    render json: { message: message }
  end

  private
    # We use a custom before_action here instead of CanCanCan's authorize_resource
    # in order to specify the :update action instead of the controller action
    # (e.g.  :regenerate_override_code).
    #
    # We could call #alias_action in Ability, but we'd have to be careful
    # that there are no action name conflicts across controllers. Attempting to
    # alias :index to :update would also break other controllers.
    def authorize_settings
      authorize!(:update, @setting)
    end

    # Prepares objects and renders the form template (which in this case is really the index template)
    def prepare_and_render_form
      @adapter_options = Sms::Adapters::Factory.products(:can_deliver? => true).map(&:service_name)
      @external_sql = Results::SqlGenerator.new(current_mission).generate unless admin_mode?
      render(:index)
    end

    def setting_params
      params.require(:setting).permit(:timezone, :preferred_locales_str,
        :incoming_sms_numbers_str, :default_outgoing_sms_adapter, :twilio_phone_number, :twilio_account_sid,
        :twilio_auth_token1, :clear_twilio, :frontlinecloud_api_key1, :clear_frontlinecloud,
        :generic_sms_config_str, :theme)
    end
end
