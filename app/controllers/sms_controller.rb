# handles incoming sms messages from various providers
class SmsController < ApplicationController
  # load resource for index
  load_and_authorize_resource :class => "Sms::Message", :only => :index

  # don't need authorize for this controller. authorization is handled inside the sms processing machinery.
  skip_authorization_check :only => :create

  # disable csrf protection for this stuff
  protect_from_forgery :except => :create

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
    @smses = @sms.latest_first.paginate(:page => params[:page], :per_page => 50)
  end

  def create
    @incoming_adapter = Sms::Adapters::Factory.new.create_for_request(params)
    raise Sms::Error.new("No adapters recognized this receive request") if @incoming_adapter.nil?

    @incoming = @incoming_adapter.receive(params)

    @incoming.update_attributes(:mission => current_mission)

    # Store the reply in an instance variable so the functional test can access them
    @reply = Sms::Handler.new.handle(@incoming)

    # Expose this to tests even if we don't use it.
    @outgoing_adapter = configatron.outgoing_sms_adapter

    if @reply
      deliver_reply(@reply) # This method does an appropriate render
    else
      render :text => '', :status => 204 # No Content
    end
  end

  private

    def deliver_reply(reply)
      # Set the incoming_sms_number as the from number
      reply.from = configatron.incoming_sms_number unless configatron.incoming_sms_number.blank?

      if @incoming_adapter.reply_style == :via_adapter
        @outgoing_adapter.deliver(reply)
        render :text => 'REPLY_SENT'
      else # reply via response
        @incoming_adapter.prepare_message_for_delivery(reply)
        render :text => reply.body
      end
    end
end
