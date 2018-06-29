shared_context "incoming sms" do
  # helper that sets up a new form with the given parameters
  def setup_form(options)
    mission = options[:mission].present? ? options[:mission] : get_mission
    if(options[:questions].all? { |q| q.is_a? Question })
      form = create(:form, :published, smsable: true, questions: options[:questions], mission: mission)
    else
      form = create(:form, :published, smsable: true, question_types: options[:questions], mission: mission)
    end
    form.questionings.each { |q| q.update_attribute(:required, true) } if options[:required]
    if options[:forward_recipients]
      form.sms_relay = true
      form.recipients = options[:forward_recipients]
    end
    form.authenticate_sms = true if options[:authenticate_sms]
    form.publish!
    form.reload
  end

  def auth_code
    @user.sms_auth_code
  end

  # simulates the reception of an incoming sms by the SmsController and tests the response(s) that is (are) sent back
  def assert_sms_response(params)
    params[:from] ||= @user.phone
    params[:sent_at] ||= Time.now
    params[:mission] = get_mission unless params.has_key?(:mission)

    # hashify incoming/outgoing if they're not hashes
    params[:incoming] = {body: params[:incoming]} unless params[:incoming].is_a?(Hash)
    params[:outgoing] = {body: params[:outgoing]} unless params[:outgoing].is_a?(Hash)

    # do post request based on params
    do_incoming_request(params)
    assert_response(:success)

    reply = Sms::Reply.first

    # if there was no reply, check that this was expected
    if reply.nil?
      expect(params[:outgoing][:body]).to be_nil
    else
      assert_instance_of(Sms::Reply, reply)
      # Ensure attribs are appropriate
      expect(reply.to).to eq(params[:from])
      expect(reply.body).to match(params[:outgoing][:body])
      expect(reply.mission).to eq(params[:mission])
      expect(reply.body).not_to match(/%\{|translation missing/)
      expect(reply.adapter_name).to eq(params[:outgoing][:adapter]) if params[:outgoing][:adapter]
    end

    reply
  end

  # builds and sends the HTTP POST request to mimic incoming adapter
  def do_incoming_request(params)
    req_params = {}
    req_env = {}

    url_prefix = defined?(missionless_url) && missionless_url ? "" : "/m/#{get_mission.compact_name}"

    if defined?(missionless_url) && missionless_url
      url_token = configatron.has_key?(:universal_sms_token) ? configatron.universal_sms_token : nil
    else
      url_token = get_mission.setting.incoming_sms_token
    end

    params[:sent_at] ||= Time.now
    params[:incoming][:adapter] ||= "TwilioSms"
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
    when "TwilioSms"
      req_params = {
        "From" => params[:from],
        "To" => "+1234567890",
        "Body" => params[:incoming][:body]
      }
      req_env = {
        "X-Twilio-Signature" => "1"
      }
    when "Generic"
      req_params = {
        "num" => params[:from],
        "msg" => params[:incoming][:body]
      }
      req_env = {
        "UserAgent" => "FooBar"
      }
    else
      raise "Incoming adapter not recognized. Can't build test request"
    end

    # do the get/post/whatever request
    send(params[:method], params[:url], params: req_params, headers: req_env)
  end

  def expect_no_messages_delivered_through_adapter
    expect(configatron.outgoing_sms_adapter.deliveries.size).to eq(0)
  end
end
