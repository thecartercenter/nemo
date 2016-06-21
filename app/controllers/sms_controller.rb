# handles incoming sms messages from various providers
class SmsController < ApplicationController
  include CsvRenderable

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
    # do search if applicable
    if params[:search].present?
      begin
        @sms = Sms::Message.do_search(@sms, params[:search])
      rescue Search::ParseError
        flash.now[:error] = $!.to_s
        @search_error = true
      end
    end

    # cancan load_resource messes up the inflection so we need to create smses from sms
    @smses = @sms.latest_first.paginate(page: params[:page], per_page: 50)
  end

  def create
    raise Sms::UnverifiedTokenError if params[:token] != current_mission.setting.incoming_sms_token

    @incoming_adapter = Sms::Adapters::Factory.new.create_for_request(request)
    raise Sms::Error.new("No adapters recognized this receive request") if @incoming_adapter.nil?

    # Create and save the message
    @incoming = @incoming_adapter.receive(request)
    @incoming.mission = current_mission
    @incoming.save

    # Store the reply in an instance variable so the functional test can access them
    @reply = Sms::Handler.new.handle(@incoming)

    # Expose this to tests even if we don't use it.
    @outgoing_adapter = configatron.outgoing_sms_adapter

    if @reply
      deliver_reply(@reply) # This method does an appropriate render
    else
      render text: "", status: 204 # No Content
    end
  end

  # Returns a CSV list of available incoming numbers.
  def incoming_numbers
    authorize!(:manage, Form)
    @numbers = configatron.incoming_sms_numbers
    render_csv("elmo-#{current_mission.compact_name}-incoming-numbers")
  end

  private

  def deliver_reply(reply)
    if @incoming_adapter.reply_style == :via_adapter
      raise Sms::Error.new("No adapter configured for outgoing response") if @outgoing_adapter.nil?
      @outgoing_adapter.deliver(reply)
    else # reply via response
      @incoming_adapter.prepare_message_for_delivery(reply)
    end

    render partial: "#{@incoming_adapter.service_name.downcase}_response", formats: [:html, :text]
  end
end
