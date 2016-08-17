module IncomingSmsSupport
  # helper that sets up a new form with the given parameters
  def setup_form(options)
    @form = create(:form, smsable: true, question_types: options[:questions])
    @form.questionings.each{ |q| q.update_attribute(:required, true) } if options[:required]
    if options[:forward_recipients]
      @form.sms_relay = true
      @form.forwardees = options[:forward_recipients]
    end
    @form.publish!
    @form.reload
  end

  # gets the version code for the current form
  def form_code
    @form.current_version.code
  end

  # simulates the reception of an incoming sms by the SmsController and tests the response(s) that is (are) sent back
  def assert_sms_response(params)
    params[:from] ||= @user.phone
    params[:sent_at] ||= Time.now

    # hashify incoming/outgoing if they're not hashes
    params[:incoming] = {body: params[:incoming]} unless params[:incoming].is_a?(Hash)
    params[:outgoing] = {body: params[:outgoing]} unless params[:outgoing].is_a?(Hash)

    # default mission to get_mission unless specified
    params[:mission] ||= get_mission

    # do post request based on params
    do_incoming_request(params)
    assert_response(:success)

    # compare the response to the outgoing spec
    sms = assigns(:reply)

    # if there was no reply, check that this was expected
    if sms.nil?
      expect(params[:outgoing][:body]).to be_nil
    else
      assert_instance_of(Sms::Reply, sms)
      # Ensure attribs are appropriate
      expect(sms.to).to eq(params[:from])
      assert_match(params[:outgoing][:body], sms.body)
      expect(sms.mission).to eq(params[:mission])
      expect(sms.body).not_to match(/%\{|translation missing/)
      expect(sms.adapter_name).to eq(params[:outgoing][:adapter]) if params[:outgoing][:adapter]
    end
  end

  # builds and sends the HTTP POST request to mimic incoming adapter
  def do_incoming_request(params)
    req_params = {}
    req_env = {}

    params[:sent_at] ||= Time.now
    params[:mission] ||= get_mission
    params[:incoming][:adapter] ||= 'IntelliSms'
    params[:url] ||= "/m/#{params[:mission].compact_name}/sms/submit/#{params[:mission].setting.incoming_sms_token}"
    params[:method] ||= :post

    case params[:incoming][:adapter]
    when "IntelliSms"
      req_params = {
        # intellisms also doesn't use the + sign
        "from" => params[:from].gsub("+", ""),
        "text" => params[:incoming][:body],
        "msgid" => "123",
        "sent" => params[:sent_at].utc.strftime("%Y-%m-%dT%T%z")
      }
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
    else
      raise "Incoming adapter not recognized. Can't build test request"
    end

    # do the get/post/whatever request
    send(params[:method], params[:url], req_params, req_env)
  end


  def expect_no_messages_delivered_through_adapter
    expect(assigns(:outgoing_adapter).deliveries.size).to eq(0)
  end
end
