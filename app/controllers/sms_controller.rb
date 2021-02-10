# frozen_string_literal: true

# handles incoming sms messages from various providers
class SmsController < ApplicationController
  include Searchable

  rescue_from Sms::UnverifiedTokenError do |_exception|
    render plain: "Unauthorized", status: :unauthorized
  end

  # load resource for index
  load_and_authorize_resource class: "Sms::Message", only: :index

  # don't need authorize for this controller. authorization is handled inside the sms processing machinery.
  skip_authorization_check only: :create

  # disable csrf protection for this stuff
  protect_from_forgery except: :create

  helper_method :smses

  def index
    @sms = apply_search(@sms)

    # cancan load_resource messes up the inflection so we need to create smses from sms
    @smses = @sms.latest_first.paginate(page: params[:page], per_page: 50)
  end

  def create
    processor = Sms::Processor.new(incoming_msg)
    processor.process

    # Missionless submission
    if current_mission.nil?
      if incoming_msg.mission
        @current_mission = incoming_msg.mission
        rebuild_incoming_adapter
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
    generator = Sms::IncomingNumberCSVGenerator.new(numbers: current_mission_config.incoming_sms_numbers)
    filename = "elmo-#{current_mission.compact_name}-incoming-numbers"
    render(csv: generator, filename: filename)
  end

  # specify the class the this controller controls, since it's not easily guessed
  def model_class
    Sms::Message
  end

  private

  def smses
    @decorated_smses ||= # rubocop:disable Naming/MemoizedInstanceVariableName
      PaginatingDecorator.decorate(@smses, with: SmsMessageDecorator)
  end

  # Builds and saves the incoming SMS message based on the request.
  def incoming_msg
    raise Sms::Error, "No adapters recognized this receive request" if incoming_adapter.nil?

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
          reply.adapter_name = "None"
          reply.reply_error_message = e
          reply.save!
        end
      else # reply via response
        incoming_adapter.prepare_message_for_delivery(reply)
      end
      render(plain: incoming_adapter.response_body(reply),
             content_type: incoming_adapter.response_content_type)
    else
      render(plain: "", status: :no_content) # No Content
    end
  end

  # Delivers the forward, if it exists, via the outgoing adapter (can't deliver this via response).
  def deliver_forward(forward)
    outgoing_adapter.deliver(forward) if forward
  end

  # Searches for adapter recognizing request. Uses mission config to populate adapter.
  # Defaults to root_config if current_mission is not available due to missionless submission.
  def incoming_adapter
    @incoming_adapter ||= Sms::Adapters::Factory.instance
      .create_for_request(request, config: current_mission&.setting || root_config)
  end

  # With missionless submission, the adapter may at first be built without full configuration.
  # Once the mission is determined, we can build it properly.
  def rebuild_incoming_adapter
    @incoming_adapter = nil
    incoming_adapter
  end

  # If no outgoing adapter is found in mission, tries root config. If still none found, raises.
  def outgoing_adapter
    return @outgoing_adapter if defined?(@outgoing_adapter)
    config = if current_mission_config.default_outgoing_sms_adapter.present?
               current_mission_config
             else
               root_config
             end
    adapter_name = config.default_outgoing_sms_adapter
    raise Sms::Error, "No adapter configured for outgoing response" if adapter_name.nil?
    @outgoing_adapter = Sms::Adapters::Factory.instance.create(adapter_name, config: config)
  end

  def verify_token(token)
    mission_token = current_mission.setting.incoming_sms_token
    global_token = Cnfg.universal_sms_token
    [mission_token, global_token].compact.include?(token)
  end
end
