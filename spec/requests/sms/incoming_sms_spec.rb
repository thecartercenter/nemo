require 'spec_helper'

describe 'incoming sms' do
  include IncomingSmsSupport

  REPLY_VIA_RESPONSE_STYLE_ADAPTER = 'FrontlineSms'

  before :all do
    @user = get_user
    setup_form(questions: %w(integer integer), required: true)
  end

  it "can accept text answers" do
    setup_form(questions: %w(text), required: true)
    assert_sms_response(incoming: "#{form_code} 1.this is a text answer", outgoing: /#{form_code}.+thank you/i)
  end

  it "can accept long_text answers" do
    setup_form(questions: %w(long_text), required: true)
    assert_sms_response(incoming: "#{form_code} 1.this is a text answer that is very very long", outgoing: /#{form_code}.+thank you/i)
  end

  it "long decimal answers have value truncated" do
    setup_form(questions: %w(decimal), required: true)
    assert_sms_response(incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
      outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  it "long integer answers have value truncated" do
    setup_form(questions: %w(integer), required: true)
    assert_sms_response(incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
      outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  it "long select_one should have value truncated" do
    setup_form(questions: %w(select_one), required: true)
    assert_sms_response(incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
      outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid option/)
  end

  it "long select_multiple should have value truncated" do
    setup_form(questions: %w(select_multiple), required: true)
    assert_sms_response(incoming: "#{form_code} 1.sfsdfsdfsdfsdf",
      outgoing: /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+contained multiple invalid options/)
  end

  it "correct message should get congrats" do
    # response should include the form code
    assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
  end

  it "GET submissions should be possible" do
    assert_sms_response(method: :get,
      incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
  end

  it "message from automated sender should get no response" do
    assert_sms_response(from: "VODAFONE", incoming: "blah blah junk", outgoing: nil)
  end

  it "message from unrecognized normal number should get error" do
    assert_sms_response(from: "+737377373773", incoming: "#{form_code} 1.x 2.x", outgoing: /couldn't find you/)
  end

  it "message inactive user should get error" do
    @user.activate!(false)
    assert_sms_response(incoming: "#{form_code} 1.x 2.x", outgoing: /couldn't find you/)
  end

  it "message with invalid answer should get error" do
    # this tests invalid answers that are caught by the decoder
    assert_sms_response(incoming: "#{form_code} 1.xx 2.20", outgoing: /Sorry.+answer 'xx'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  it "message with invalid options should get error" do
    # override the default form
    setup_form(questions: %w(select_multiple))
    assert_sms_response(incoming: "#{form_code} 1.abhk", outgoing: /Sorry.+answer 'abhk'.+contained invalid options 'h, k'/)
    assert_sms_response(incoming: "#{form_code} 1.abh", outgoing: /Sorry.+answer 'abh'.+contained the invalid option 'h'/)
  end

  it "bad encoding should get error" do
    # for instance, try to submit with bad form code
    # we don't have to try all the encoding errors b/c that's covered in the decoder test
    assert_sms_response(incoming: "123", outgoing: /not a valid form code/i)
  end

  it "missing answer should get error" do
    assert_sms_response(incoming: "#{form_code} 2.20", outgoing: /answer.+required question 1 was.+#{form_code}/)
    assert_sms_response(incoming: "#{form_code}", outgoing: /answers.+required questions 1,2 were.+#{form_code}/)
  end

  it "too high numeric answer should get error" do
    # add a maximum constraint to the first question
    @form.unpublish!
    @form.questions.first.update_attributes!(maximum: 20)
    @form.publish!

    # check that it works
    assert_sms_response(incoming: "#{form_code} 1.21 2.21", outgoing: /Must be less than or equal to 20/)
  end

  it "duplicate should result error message" do
    assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /#{form_code}.+thank you/i)
    Timecop.travel(10.minutes) do
      assert_sms_response(incoming: "#{form_code} 1.15 2.20", outgoing: /duplicate/)
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

    do_incoming_request(url: "/m/#{get_mission.compact_name}/sms/submit/#{token}",
      incoming: {body: "#{form_code} 1.15 2.20", adapter: REPLY_VIA_RESPONSE_STYLE_ADAPTER})
    expect(@response.status).to eq(401)
  end

  context "with SMS relay enabled" do
    let(:users) { create_list(:user, 2) }
    let(:group) { create(:user_group, users: create_list(:user, 3)) }
    let(:forwardees) { users + [group] }

    before { setup_form(questions: %w(integer text), forward_recipients: forwardees) }

    it "sends forwards" do
      incoming_body = "#{form_code} 1.15 2.something"
      assert_sms_response(incoming: incoming_body , outgoing: /#{form_code}.+thank you/i)

      # get forward
      sms_forward = Sms::Forward.last
      expect(sms_forward.body).to eq incoming_body

      # get forward recipients
      recipients = sms_forward.recipient_hashes.map { |hash| hash[:user] }
      expect(recipients).to contain_exactly(*(users + group.users))
    end

    context "with sms authentication enabled" do
      before { setup_form(questions: %w(integer text), forward_recipients: forwardees, authenticate_sms: true) }

      it "strips auth code from forward" do
        incoming_body = "#{auth_code} #{form_code} 1.29 2.something"
        assert_sms_response(incoming: incoming_body, outgoing: /#{form_code}.+thank you/i)
        sms_forward = Sms::Forward.last
        expect(sms_forward.body).to eq "#{form_code} 1.29 2.something"
      end
    end
  end
end
