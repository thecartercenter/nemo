# frozen_string_literal: true

shared_context "incoming sms" do
  let(:user) { get_user }
  let(:missionless_url) { false }

  # helper that sets up a new form with the given parameters
  def setup_form(options)
    mission = options[:mission].presence || get_mission
    form = if options[:questions].all? { |q| q.is_a?(Question) }
             create(:form, :live, smsable: true, questions: options[:questions], mission: mission)
           else
             create(:form, :live, smsable: true, question_types: options[:questions], mission: mission)
           end
    form.questionings.each { |q| q.update_attribute(:required, true) } if options[:required]
    if options[:forward_recipients]
      form.sms_relay = true
      form.recipients = options[:forward_recipients]
    end
    form.authenticate_sms = true if options[:authenticate_sms]
    form.save!
    form.reload
  end

  # Simulates the reception of an incoming sms by the SmsController
  # and tests the response(s) that is (are) sent back. Returns the Sms::Reply object.
  def assert_sms_response(params)
    do_incoming_request(params)
    assert_response(:success)

    reply = Sms::Reply.first
    if reply.nil?
      expect(params[:outgoing][:body]).to be_nil
    else
      expect(reply.to).to eq(params[:from])
      expect(reply.body).to match(params[:outgoing][:body])
      expect(reply.mission).to eq(params[:mission])
      expect(reply.body).not_to match(/%\{|translation missing/)
      expect(reply.adapter_name).to eq(params[:outgoing][:adapter]) if params[:outgoing][:adapter]
    end
    reply
  end

  # Builds and sends the request.
  def do_incoming_request(params)
    send(*build_incoming_request(params))
  end

  # Builds the method, url, params, and headers for the incoming request to mimic the incoming adapter.
  def build_incoming_request(params)
    req_params = {}
    req_headers = params[:headers] || {}

    url_prefix = missionless_url ? "" : "/m/#{get_mission.compact_name}"
    url_token = missionless_url ? universal_sms_token : get_mission.setting.incoming_sms_token

    params[:from] ||= user.phone
    params[:mission] = get_mission unless params.key?(:mission)
    params[:incoming] = {body: params[:incoming]} unless params[:incoming].is_a?(Hash)
    params[:outgoing] = {body: params[:outgoing]} unless params[:outgoing].is_a?(Hash)
    params[:sent_at] ||= Time.current
    params[:incoming][:adapter] ||= "Twilio"
    params[:url] ||= "#{url_prefix}/sms/submit/#{url_token}"
    params[:method] ||= :post

    case params[:incoming][:adapter]
    when "FrontlineSms"
      req_params = {
        "from" => params[:from],
        "text" => params[:incoming][:body],
        "sent" => params[:sent_at].utc.strftime("%Y-%m-%d %T.%L"),
        "frontline" => "1"
      }
    when "FrontlineCloud"
      req_params = {
        "from" => params[:from],
        "body" => params[:incoming][:body],
        "sent_at" => params[:sent_at].strftime("%s"),
        "frontlinecloud" => "1"
      }
    when "Twilio"
      req_params = {
        "From" => params[:from],
        "To" => "+1234567890",
        "Body" => params[:incoming][:body]
      }
      req_headers = {
        "X-Twilio-Signature" => "1"
      }
    when "Generic"
      req_params = {
        "num" => params[:from],
        "msg" => params[:incoming][:body]
      }
    else
      raise "Incoming adapter not recognized. Can't build test request"
    end

    [params[:method], params[:url], {params: req_params, headers: req_headers}]
  end

  def expect_no_messages_delivered_through_adapter(&block)
    expect { block.call }.to change { Sms::Adapters::Adapter.deliveries.size }.by(0)
  end
end
