require 'test_helper'
require 'sms_forms_test_helper'

class SmsControllerTest < ActionController::TestCase

  setup do
    clear_objects(Form, Question, Questioning, Option, OptionSet, Optioning, Response)
    @user = get_user

    # we only need one form for all these tests, with two integer questions, both required
    setup_form(:questions => %w(integer integer), :required => true)
  end

  test "correct message should get congrats" do
    # response should include the form code
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
  end

  test "message from robot should get no response" do
    assert_sms_response(:from => "VODAFONE", :incoming => "blah blah junk", :outgoing => nil)
  end

  test "message from unrecognized normal number should get error" do
    assert_sms_response(:from => "+737377373773", :incoming => "#{form_code} 1.x 2.x", :outgoing => /couldn't find you/)
  end

  test "message with invalid answer should get error" do
    # this tests invalid answers that are caught by the decoder
    assert_sms_response(:incoming => "#{form_code} 1.xx 2.20", :outgoing => /Sorry.+answer 'xx'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  test "message with invalid options should get error" do
    # override the default form
    setup_form(:questions => %w(select_multiple))
    assert_sms_response(:incoming => "#{form_code} 1.abhk", :outgoing => /Sorry.+answer 'abhk'.+contained invalid options 'h, k'/)
    assert_sms_response(:incoming => "#{form_code} 1.abh", :outgoing => /Sorry.+answer 'abh'.+contained the invalid option 'h'/)
  end

  test "bad encoding should get error" do
    # for instance, try to submit with bad form code
    # we don't have to try all the encoding errors b/c that's covered in the decoder test
    assert_sms_response(:incoming => "123", :outgoing => /not a valid form code/i)
  end

  test "missing answer should get error" do
    assert_sms_response(:incoming => "#{form_code} 2.20", :outgoing => /answer.+required question 1 was.+#{form_code}/)
    assert_sms_response(:incoming => "#{form_code}", :outgoing => /answers.+required questions 1,2 were.+#{form_code}/)
  end

  test "too high numeric answer should get error" do
    # add a maximum constraint to the first question
    @form.unpublish!
    @form.questions.first.update_attributes!(:maximum => 20)
    @form.publish!

    # check that it works
    assert_sms_response(:incoming => "#{form_code} 1.21 2.21", :outgoing => /question \d+ must be less than or equal to 20/)
  end

  test "date and time should be picked from xml" do
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i,
      :sent_at => Time.parse("2012 Mar 7 8:07:20 UTC"))

    # our timezone is -6 and the ISMS is UTC, so adjust accordingly
    assert_equal(Time.zone.parse("2012 Mar 7 2:07:20"), assigns(:incomings).first.sent_at)
  end

  test "duplicate should result error message" do
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
    Timecop.travel(10.minutes) do
      assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /duplicate/)
    end
  end

  test "reply should be in correct language" do
    # set user lang pref to french
    @user.pref_lang = "fr"
    @user.save(:validate => false)

    # now try to send to the new form (won't work b/c no permission)
    assert_sms_response(:incoming => "#{form_code} 1.15 2.b", :outgoing => /votre.+#{form_code}/i)
  end

  test "message should go out on outgoing adapter for incoming mission" do
    # setup the current mission
    @mission = get_mission

    # set the outgoing adapter for the mission to IntelliSMS and check that it gets used even if incoming adapter is Isms
    @mission.setting.update_attributes(:outgoing_sms_adapter => "IntelliSms")
    assert_sms_response(:mission => @mission, :incoming => {:body => "#{form_code} 1.15 2.20", :adapter => "Isms"},
      :outgoing => {:body => /thank you/i, :adapter => "IntelliSms"})

    # set the outgoing adapter for the mission to Isms and check that it gets used even if incoming adapter is Intellisms
    @mission.setting.update_attributes(:outgoing_sms_adapter => "Isms")
    assert_sms_response(:mission => @mission, :incoming => {:body => "#{form_code} 1.15 2.21", :adapter => "IntelliSms"},
      :outgoing => {:body => /thank you/i, :adapter => "Isms"})
  end

  private
    # simulates the reception of an incoming sms by the SmsController and tests the response(s) that is (are) sent back
    def assert_sms_response(params)
      # default to user phone and time of now
      params[:from] ||= @user.phone
      params[:sent_at] ||= Time.now

      # hashify incoming/outgoing if they're not hashes
      params[:incoming] = {:body => params[:incoming]} unless params[:incoming].is_a?(Hash)
      params[:outgoing] = {:body => params[:outgoing]} unless params[:outgoing].is_a?(Hash)

      # default mission to get_mission unless specified
      params[:mission] ||= get_mission

      # assume the message came in on the Isms adapter if not set
      params[:incoming][:adapter] ||= "Isms"

      # do post request based on params
      do_post_request(params)

      # compare the response to the outgoing spec
      sms = assigns(:sms_replies).first

      # if there was no reply, check that this was expected
      if sms.nil?
        assert_nil(params[:outgoing][:body])
      else

        # ensure the to matches the from
        assert_equal(params[:from], sms.to.first)

        # ensure the body is as expected
        assert_match(params[:outgoing][:body], sms.body)

        # ensure the body is not missing translations
        assert_no_match(/%\{|translation missing/, sms.body)

        # ensure the outgoing adapter is correct, if it is set in params
        assert_equal(params[:outgoing][:adapter], sms.adapter_name) if params[:outgoing][:adapter]
      end
    end

    # builds and sends the HTTP POST request to mimic incoming adapter
    def do_post_request(params)
      req_params = nil

      case params[:incoming][:adapter]
      when "Isms"
        # isms doesn't use the + sign
        from = params[:from].gsub("+", "")

        # get time and date in isms style
        date = params[:sent_at].utc.strftime("%y/%m/%d")
        time = params[:sent_at].utc.strftime("%H:%M:%S")

        # get the xml for the message
        message_xml = "<MessageNotification><ModemNumber>2:19525945092</ModemNumber><SenderNumber>#{from}</SenderNumber><Date>#{date}</Date><Time>#{time}</Time>
            <Message>#{params[:incoming][:body]}</Message></MessageNotification>"

        # build and set req params
        req_params = {
          "XMLDATA" => "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><Response>#{message_xml}</Response>"
        }

        # set the appropriate user agent header (needed)
        @request.env["User-Agent"] = "MultiModem iSMS/1.41"

      when "IntelliSms"

        req_params = {
          # intellisms also doesn't use the + sign
          "from" => params[:from].gsub("+", ""),
          "text" => params[:incoming][:body],
          "msgid" => "123",
          "sent" => params[:sent_at].utc.strftime("%Y-%m-%dT%T%z")
        }

      end

      # set the mission parameter that will be picked up and decoded by the controller
      req_params["mission"] = params[:mission].compact_name

      # do the post request
      post(:create, req_params)
    end
end
