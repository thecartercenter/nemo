# handles incoming sms messages from various providers
class SmsController < ApplicationController
  include CsvRenderable, Searchable

  rescue_from Sms::UnverifiedTokenError do |exception|
    render plain: "Unauthorized", status: :unauthorized
  end

  # load resource for index
  load_and_authorize_resource class: "Sms::Message", only: :index

  # don't need authorize for this controller. authorization is handled inside the sms processing machinery.
  skip_authorization_check only: :create

  # disable csrf protection for this stuff
  protect_from_forgery except: :create

  def index
    @sms = apply_search_if_given(Sms::Message, @sms)

    # cancan load_resource messes up the inflection so we need to create smses from sms
    @smses = @sms.latest_first.paginate(page: params[:page], per_page: 50)
  end

  def create
    processor = Sms::Processor.new(incoming_msg)
    processor.process

    if current_mission.nil?
      if incoming_msg.mission
        @current_mission = incoming_msg.mission
        load_settings_for_mission_into_config if current_mission
      else
        # If we get to this point, the reply waiting to be sent must be a complaint of form not found,
        # since if it were found, the mission would be stored on the incoming_msg by now.
        # So we just send the reply and quit.
        deliver_reply(processor.reply)
        return
      end
    end

    # Mission is guaranteed to be set by this point.
    raise Sms::UnverifiedTokenError unless verify_token(params[:token])

    incoming_adapter.validate(request)

    processor.finalize
    deliver_reply(processor.reply)
    deliver_forward(processor.forward)
  end

  # Returns a CSV list of available incoming numbers.
  def incoming_numbers
    authorize!(:manage, Form)
    @numbers = configatron.incoming_sms_numbers
    render_csv("elmo-#{current_mission.compact_name}-incoming-numbers")
  end

  private

  # Builds and saves the incoming SMS message based on the request.
  def incoming_msg
    raise Sms::Error.new("No adapters recognized this receive request") if incoming_adapter.nil?

    # Create and save the message
    @incoming_msg ||= incoming_adapter.receive(request).tap do |msg|
      msg.mission = current_mission
      msg.save
    end
  end

  # Sends the reply via an adapter or renders an appropriate response, depending on the reply type.
  def deliver_reply(reply)
    if reply
      if incoming_adapter.reply_style == :via_adapter
        begin
          raise Sms::Error, ENV["STUB_REPLY_ERROR"] if Rails.env.test? && ENV["STUB_REPLY_ERROR"].present?
          outgoing_adapter.deliver(reply)
        rescue Sms::Error => e
          reply.error_message = e
          reply.save!
        end
      else # reply via response
        incoming_adapter.prepare_message_for_delivery(reply)
      end
      render incoming_adapter.response_format => incoming_adapter.response_body(reply)
    else
      render plain: "", status: 204 # No Content
    end
  end

  # Delivers the forward, if it exists, via the outgoing adapter (can't deliver this via response).
  def deliver_forward(forward)
    outgoing_adapter.deliver(forward) if forward
  end

  def incoming_adapter
    return @incoming_adapter if defined?(@incoming_adapter)
    @incoming_adapter = Sms::Adapters::Factory.instance.create_for_request(request)
  end

  # Returns the outgoing adapter. If none is found, tries default settings. If still none found, raises.
  def outgoing_adapter
    if configatron.outgoing_sms_adapter
      configatron.outgoing_sms_adapter
    elsif (default_adapter_name = configatron.default_settings.outgoing_sms_adapter).present?
      Sms::Adapters::Factory.instance.create(default_adapter_name, config: configatron.default_settings)
    else
      raise Sms::Error.new("No adapter configured for outgoing response")
    end
  end

  def verify_token(token)
    mission_token = current_mission.setting.incoming_sms_token
    global_token = configatron.has_key?(:universal_sms_token) ? configatron.universal_sms_token : nil

    [mission_token, global_token].compact.include? token
  end
end
