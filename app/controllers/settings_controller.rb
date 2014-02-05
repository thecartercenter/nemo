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

      if params[:regenerate]
        @setting.generate_override_code!
      else
        @setting.update_attributes!(params[:setting])
      end

      set_success_and_redirect(@setting)
    rescue ActiveRecord::RecordInvalid
      prepare_and_render_form
    end
  end

  private
    # prepares objects and renders the form template (which in this case is really the index template)
    def prepare_and_render_form
      # load options for sms adapter dropdown
      @adapter_options = Sms::Adapters::Factory::VALID_ADAPTERS

      unless admin_mode?
        # get external sql from Response class
        @external_sql = Response.export_sql(Response.accessible_by(current_user.ability))
      end

      # render the template
      render(:index)
    end
end
