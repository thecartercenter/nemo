# handles incoming sms messages from various providers
class SmsController < ApplicationController
  # load resource for index
  load_and_authorize_resource :class => "Sms::Message", :only => :index

  # don't need authorize for this controller. authorization is handled inside the sms processing machinery.
  skip_authorization_check :only => :create

  # disable csrf protection for this stuff
  protect_from_forgery :except => :create

  def index
    # cancan load_resource messes up the inflection so we need to create smses from sms
    @smses = @sms.newest_first.paginate(:page => params[:page], :per_page => 50)
  end

  def create
    # get the mission from the params. if not found raise an error (we need the mission)
    mission = Mission.find_by_compact_name(params[:mission])
    raise Sms::Error.new("Mission not specified") if mission.nil?

    adapter = Sms::Adapters::Factory.new.create_for_request(params)

    raise Sms::Error.new("no adapters recognized this receive request") if adapter.nil?

    @incoming = adapter.receive(request.POST)

    @incoming.update_attributes(:mission => mission)

    # Store the reply in an instance variable so the functional test can access them
    @reply = Sms::Handler.new.handle(@incoming)

    deliver_reply(@reply) unless @reply.nil?

    # render something nice for the robot
    render :text => "OK"
  end

  private

    def deliver_reply(reply)
      # Copy settings from the message's mission
      # This is so that the incoming_sms_number is available below.
      reply.mission && reply.mission.setting ? reply.mission.setting.load : Setting.build_default.load

      # Set the incoming_sms_number as the from number, if we have one
      reply.update_attributes(:from => configatron.incoming_sms_number) unless configatron.incoming_sms_number.blank?

      configatron.outgoing_sms_adapter.deliver(reply)
    end
end
