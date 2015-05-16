class SettingsController < ApplicationController
  # no authorization up here because we do it manually because Setting is atypical

  def index
    # setting is already loaded by application controller

    # do authorization check
    authorize!(:update, @setting)

    prepare_and_render_form
  end

  def update
    begin
      # setting is already loaded by application controller

      # do auth check so cancan doesn't complain
      authorize!(:update, @setting)

      @setting.update_attributes!(setting_params)

      set_success_and_redirect(@setting)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = I18n.t('activerecord.errors.models.setting.general')
      prepare_and_render_form
    end
  end

  def regenerate_override_code
    # do auth check so cancan doesn't complain
    authorize!(:update, @setting)

    @setting.generate_override_code!

    render json: { value: @setting.override_code }
  end

  def regenerate_incoming_sms_token
    # do auth check so cancan doesn't complain
    authorize!(:update, @setting)

    @setting.regenerate_incoming_sms_token!

    render json: { value: @setting.incoming_sms_token }
  end

  def using_incoming_sms_token_message
    # do auth check so cancan doesn't complain
    authorize!(:update, @setting)

    url = mission_sms_submission_url(@setting.incoming_sms_token, locale: nil)
    message = t('activerecord.hints.setting.using_incoming_sms_token_body', url: url)

    render json: { message: message }
  end

  private
    # prepares objects and renders the form template (which in this case is really the index template)
    def prepare_and_render_form
      # load options for sms adapter dropdown
      @adapter_options = Sms::Adapters::Factory.products(:can_deliver? => true).map(&:service_name)

      unless admin_mode?
        # get external sql from Response class
        @external_sql = Response.export_sql(Response.accessible_by(current_ability))
      end

      # render the template
      render(:index)
    end

    def setting_params
      params.require(:setting).permit(:timezone, :preferred_locales_str, :allow_unauthenticated_submissions,
        :incoming_sms_number, :outgoing_sms_adapter, :intellisms_username, :intellisms_password1, :intellisms_password2,
        :twilio_account_sid, :twilio_auth_token1, :twilio_auth_token2)
    end
end
