require "rails_helper"

describe "incoming sms", :sms do
  include_context "incoming sms"

  REPLY_VIA_RESPONSE_STYLE_ADAPTER = "FrontlineSms"

  let(:form) { setup_form(questions: %w(integer integer), required: true) }
  let(:form_code) { form.current_version.code }
  let(:wrong_code) { form_code.sub(form.code[0], form.code[0] == "a" ? "b" : "a") }
  let(:bad_incoming_token) { "0" * 32 }

  before :all do
    @user = get_user
    configatron.universal_sms_token = SecureRandom.hex
  end

  context "with text form" do
    let(:form) { setup_form(questions: %w(text), required: true) }

    it "can accept text answers" do
      assert_sms_response(incoming: "#{form_code} 1.this is a text answer", outgoing: /#{form_code}.+thank you/i)
      # Ensure objects are persisted
      expect(Sms::Incoming.count).to eq 1
      expect(Sms::Reply.count).to eq 1
    end
  end

  context "with long_text form" do
    let(:form) { setup_form(questions: %w(long_text), required: true) }

    it "can accept long_text answers" do
      assert_sms_response(
        incoming: "#{form_code} 1.this is a text answer that is very very long",
        outgoing: /#{form_code}.+thank you/i)
    end
  end

  context "with decimal form" do
    let(:form) { setup_form(questions: %w(decimal), required: true) }

    it "long decimal answers have value truncated" do
      assert_sms_response(
        incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
        outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
    end
  end

  context "with integer form" do
    let(:form) { setup_form(questions: %w(integer), required: true) }
    it "long integer answers have value truncated" do
      assert_sms_response(
        incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
        outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
    end
  end

  context "with select_one form" do
    let(:form) { setup_form(questions: %w(select_one), required: true) }
    it "long select_one should have value truncated" do
      assert_sms_response(
        incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
        outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid option/)
    end
  end

  context "with datetime form" do
    let(:form) { setup_form(questions: %w(datetime)) }

    before do
      form.mission.setting.update!(timezone: "Saskatchewan")
    end

    it "timezone should be handled properly" do
      assert_sms_response(
        incoming: "#{form_code} 1.201701011230",
        outgoing: /#{form_code}.+thank you/i)
      expect(Answer.first.datetime_value.to_s).to eq "2017-01-01 12:30:00 -0600"
    end
  end

  context "with select_multiple form" do
    let(:form) { setup_form(questions: %w(select_multiple), required: true) }

    it "long select_multiple should have value truncated" do
      assert_sms_response(
        incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
        outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+contained multiple invalid options/)
    end

    it "message with one invalid option should get error" do
      assert_sms_response(
        incoming: "#{form_code} 1.abh",
        outgoing: /Sorry.+answer 'abh'.+contained the invalid option 'h'/)
    end

    it "message with multiple invalid options should get error" do
      assert_sms_response(
        incoming: "#{form_code} 1.abhk",
        outgoing: /Sorry.+answer 'abhk'.+contained invalid options 'h, k'/)
    end
  end

  it "correct message should get congrats" do
    # response should include the form code
    assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
  end

  it "should save error message if there is an error in reply" do
    with_env("STUB_REPLY_ERROR" => "I am the reply error") do
      assert_sms_response(
        incoming: {body: "#{form_code} 1.15 2.20", adapter: "FrontlineCloud"},
        outgoing: {body: "Your response to form '#{form_code}' was received. Thank you!"}
      )
      expect(Sms::Reply.count).to eq(1)
      expect(Sms::Reply.first.error_message).to eq("I am the reply error")
    end
  end

  it "GET submissions should be possible" do
    assert_sms_response(method: :get, incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
  end

  it "message from automated sender should get no response" do
    assert_sms_response(from: "VODAFONE", incoming: "blah blah junk", outgoing: nil)
    expect(Sms::Reply.count).to eq 0
  end

  context "from unrecognized normal number" do
    it "should get error reply" do
      assert_sms_response(from: "+737377373773", incoming: "#{form_code} 1.x 2.x",
        outgoing: /couldn't find you/)
    end

    context "with missionless url" do
      let(:missionless_url) { true }

      it "should get error reply" do
        assert_sms_response(from: "+737377373773", incoming: "#{form_code} 1.x 2.x",
          outgoing: /couldn't find you/)
      end
    end
  end

  it "message inactive user should get error" do
    @user.activate!(false)
    assert_sms_response(incoming: "#{form_code} 1.x 2.x", outgoing: /couldn't find you/)
  end

  it "message with invalid answer should get error" do
    # this tests invalid answers that are caught by the decoder
    assert_sms_response(
      incoming: "#{form_code} 1.xx 2.20",
      outgoing: /Sorry.+answer 'xx'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  it "bad encoding should get error" do
    # for instance, try to submit with bad form code
    # we don't have to try all the encoding errors b/c that's covered in the decoder test
    assert_sms_response(incoming: "123", outgoing: /not a valid form code/i)
  end

  it "message missing one answer should get error" do
    assert_sms_response(incoming: "#{form_code} 2.20", outgoing: /answer.+required question 1 was.+#{form_code}/)
  end

  it "message missing multiple answers should get error" do
    assert_sms_response(incoming: "#{form_code}", outgoing: /answers.+required questions 1,2 were.+#{form_code}/)
  end

  it "too high numeric answer should get error" do
    # add a maximum constraint to the first question
    form.unpublish!
    form.questions.first.update_attributes!(maximum: 20)
    form.publish!

    # check that it works
    assert_sms_response(incoming: "#{form_code} 1.21 2.21", outgoing: /was not less than or equal to 20/)
  end

  context "duplicate response" do
    before do
      create(:sms_incoming, from: @user.phone, body: "#{form_code} 1.15 2.20", sent_at: Time.now)
    end

    it "should result in error message" do
      Timecop.travel(10.minutes) do
        assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /duplicate/)
        expect(Sms::Incoming.count).to eq 2
      end
    end

    context "with missionless url" do
      let(:missionless_url) { true }

      it "should still result in error message" do
        Timecop.travel(10.minutes) do
          assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /duplicate/)
        end
      end
    end
  end

  it "reply should be in correct language" do
    # set user lang pref to french
    @user.pref_lang = "fr"
    @user.save(validate: false)

    # now try to send to the new form (won't work b/c no permission)
    assert_sms_response(incoming: "#{form_code} 1.15 2.b", outgoing: /votre.+#{form_code}/i)
  end

  it "fails when the incoming SMS token is incorrect" do
    begin
      token = SecureRandom.hex
    end while token == get_mission.setting.incoming_sms_token

    do_incoming_request(
      url: "/m/#{get_mission.compact_name}/sms/submit/#{token}",
      incoming: { body: "#{form_code} 1.15 2.20", adapter: REPLY_VIA_RESPONSE_STYLE_ADAPTER })
    expect(@response.status).to eq(401)
  end

  context "with failing Twilio validation" do
    let(:twilio_adapter) { Sms::Adapters::Factory.instance.create("Twilio") }

    before do
      expect(twilio_adapter).to receive(:validate).and_raise(Sms::Error)
      expect(Sms::Adapters::Factory.instance).to receive(:create_for_request).and_return(twilio_adapter)
    end

    it "should raise error" do
      expect do
        do_incoming_request(url: "/m/#{get_mission.compact_name}/sms/submit/#{get_mission.setting.incoming_sms_token}",
          from: @user.phone, incoming: {body: "#{form_code} 1.15 2.20", adapter: "TwilioSms"})
      end.to raise_error(Sms::Error)
    end
  end

  context "with SMS relay enabled" do
    let(:users) { create_list(:user, 2) }
    let(:group) { create(:user_group, users: create_list(:user, 3)) }
    let(:recipients) { users + [group] }
    let(:form) { setup_form(questions: %w(integer text), forward_recipients: recipients) }
    let(:sms_forward) { Sms::Forward.first }
    let(:actual_recipients) { sms_forward.recipient_hashes.map { |hash| hash[:user] } }

    shared_examples_for "sends forwards" do
      it "sends forwards" do
        incoming_body = "#{form_code} 1.15 2.something"
        assert_sms_response(incoming: incoming_body , outgoing: /#{form_code}.+thank you/i)
        expect(sms_forward.body).to eq incoming_body
        expect(actual_recipients).to contain_exactly(*(users + group.users))
        expect(Broadcast.count).to eq 1 # Ensure persisted
      end
    end

    context "normally" do
      it_behaves_like "sends forwards"
    end

    context "with answer error" do
      let(:integer_q) { create(:question, qtype_name: "integer", minimum: 20) }
      let(:text_q) { create(:question, qtype_name: "text") }
      let(:form) { setup_form(questions: [integer_q, text_q], forward_recipients: recipients) }

      it "does not send forwards" do
        incoming_body = "#{form_code} 1.15 2.something"
        assert_sms_response(incoming: incoming_body, outgoing: /was not greater than or equal to 20/)
        expect(sms_forward).to be_nil
        expect(Broadcast.count).to eq 0
      end
    end

    context "with sms authentication enabled" do
      let(:form) { setup_form(questions: %w(integer text), forward_recipients: recipients, authenticate_sms: true) }

      it "strips auth code from forward" do
        incoming_body = "#{auth_code} #{form_code} 1.20 2.something"
        assert_sms_response(incoming: incoming_body, outgoing: /#{form_code}.+thank you/i)
        expect(sms_forward.body).to eq "#{form_code} 1.20 2.something"
      end
    end

    context "with missionless url" do
      let(:missionless_url) { true }
      it_behaves_like "sends forwards"

      context "with invalid token" do
        it "raises error and doesn't persist broacast or forward" do
          do_incoming_request(url: "/sms/submit/#{bad_incoming_token}", from: @user.phone,
            incoming: {body: "#{form_code} 1.15 2.something", })
          expect(@response.status).to eq(401)
          expect(Broadcast.count).to eq 0
          expect(Sms::Forward.count).to eq 0
          expect(Response.count).to eq 0
        end
      end
    end
  end

  context "with missionless url" do
    # TODO: I am thinking this is how we should refactor this spec: change assert_sms_response into
    # a custom matcher and define any special request options in a `let`.
    # For now I'm checking request_options in the helper method.
    let(:missionless_url) { true }

    it "should process correctly with valid form code" do
      assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
      expect(Sms::Incoming.first.mission).to eq get_mission
      expect(Sms::Reply.first.mission).to eq get_mission
    end

    it "should send reply if form not found" do
      assert_sms_response(incoming: "#{wrong_code} 1.15 2.20",
        outgoing: /there is no form with code/, mission: nil)
    end

    context "with multiple missions" do
      let(:first_mission) { get_mission }
      let(:second_mission) { create(:mission, with_user: @user) }
      let(:first_form) { setup_form(questions: %w(integer text), mission: first_mission) }
      let(:second_form) { setup_form(questions: %w(integer text), mission: second_mission) }
      let(:first_form_code) { first_form.current_version.code }
      let(:second_form_code) { second_form.current_version.code }
      let(:submission_url) { "/sms/submit/#{configatron.universal_sms_token}" }

      it "should process first mission correctly with valid form code" do
        assert_sms_response(
          mission: first_mission,
          incoming: "#{first_form_code} 1.15 2.oooh",
          outgoing: /#{first_form_code}.+thank you/i,
          url: submission_url)
      end

      it "should process second mission correctly with valid form code" do
        assert_sms_response(
          mission: second_mission,
          incoming: "#{second_form_code} 1.15 2.oooh",
          outgoing: /#{second_form_code}.+thank you/i,
          url: submission_url)
      end
    end

    context "with reply via_adapter adapter" do
      context "with default adapter" do
        before do
          configatron.default_settings.outgoing_sms_adapter = "Twilio"
        end

        it "should send reply via default adapter if form not found" do
          assert_sms_response(incoming: {body: "#{wrong_code} 1.15 2.20", adapter: "FrontlineCloud"},
                              outgoing: {body: /there is no form with code/, adapter: "Twilio"}, mission: nil)
        end
      end

      context "without default adapter" do
        before do
          configatron.default_settings.outgoing_sms_adapter = ""
        end

        it "should save error on reply message" do
          assert_sms_response(incoming: {body: "#{wrong_code} 1.15 2.20", adapter: "FrontlineCloud"},
                              outgoing: {body: /there is no form with code/}, mission: nil)
          expect(Sms::Reply.first.error_message).to match(/No adapter configured for outgoing response/)
        end
      end
    end
  end

  context "with duplicate phone numbers" do
    # setup extra mission
    let!(:missionless_url) { true }
    let!(:submission_url) { "/sms/submit/#{configatron.universal_sms_token}" }
    let!(:extra_mission) { create(:mission) }

    # setup users
    let!(:auth_code_user) { create(:user, phone: "+1-646-555-2638") }
    let!(:mission_user) { create(:user, phone2: "+1-646-555-2638", mission: extra_mission) }
    let!(:oldest_user) { create(:user, phone: "+1-646-555-2638", created_at: 2.months.ago) }

    # setup forms
    let!(:authenticated_form) { setup_form(questions: %w(integer text), authenticate_sms: true) }
    let!(:mission_form) { setup_form(questions: %w(integer text), mission: extra_mission) }
    let!(:oldest_form) { setup_form(questions: %w(integer text)) }

    it "should get the user with the matching auth code if it's available" do
      reply = assert_sms_response(
        from: auth_code_user.phone,
        incoming: { body: "#{auth_code_user.sms_auth_code} #{authenticated_form.code} 1.5 2.Y" },
        outgoing: /#{authenticated_form.code}.+thank you/i,
        url: submission_url)
      user = reply.user
      expect(user.id).to eq auth_code_user.id
    end

    it "should get the user that matches the mission if it cannot match the auth code" do
      reply = assert_sms_response(
        from: mission_user.phone2,
        incoming: { body: "#{mission_form.code} 1.5 2.Y" },
        outgoing: /#{mission_form.code}.+thank you/i,
        mission: extra_mission,
        url: submission_url)
      user = reply.user
      expect(user.id).to eq mission_user.id
    end

    it "should get the oldest user otherwise" do
      reply = assert_sms_response(
        from: oldest_user.phone,
        incoming: { body: "#{oldest_form.code} 1.5 2.Y" },
        outgoing: /#{oldest_form.code}.+thank you/i,
        url: submission_url)
      user = reply.user
      expect(user.id).to eq oldest_user.id
    end
  end
end
