require 'test_helper'
require 'sms_forms_test_helper'

class SmsControllerTest < ActionController::TestCase

  setup do
    [Form, Question, Questioning, Option, OptionSet, OptionSetting, Response].each{|k| k.delete_all}
    @user = get_user
    
    # load settings for the missionWithSettings mission so that we get the isms adapter, which we will use to craft the test messages
    Setting.mission_was_set(get_mission)
    
    # we only need one form for all these tests, with two integer questions, both required
    setup_form(:questions => %w(integer integer), :required => true)
  end

  test "correct message should get congrats" do
    # response should include the form code
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
  end
  
  test "message from robot should get no response" do
    assert_sms_response(:from => "VODAFONE", :incoming => "blah blah junk", :outgoing => [])
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
  
  test "multiple incoming messages should work" do
    assert_sms_response(:incoming => ["#{form_code} 1.15 2.20", "#{form_code} 1.19 2.21"], 
      :outgoing => [/#{form_code}.+thank you/i, /#{form_code}.+thank you/i])
  end
  
  test "date and time should be picked from xml" do
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i, 
      :sent_at => Time.parse("2012 Mar 7 8:07:20 UTC"))
      
    # our timezone is -6 and the ISMS is UTC, so adjust accordingly
    assert_equal(Time.zone.parse("2012 Mar 7 2:07:20"), assigns(:incomings).first.sent_at)
  end
  
  test "duplicate should result in no reply" do
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
    Timecop.travel(10.minutes) do
      assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => [])
    end
  end

  test "reply should be in correct language" do
    # create another mission with a different outgoing sms language
    m = FactoryGirl.create(:mission, :name => "francais", :outgoing_lang => "fr")

    # now create a form in that mission
    setup_form(:questions => %w(integer select_one), :required => true, :mission => m)
    
    # now try to send to the new form (won't work b/c no permission)
    assert_sms_response(:incoming => "#{form_code} 1.15 2.b", :outgoing => /permission.+soumettre.+#{form_code}/i)
    
    # add the user to the mission
    @user.assignments.create(:mission => m, :active => true, :role => User::ROLES.last)
    
    # try again -- should get merci (need different answers else ignored as duplciate)
    assert_sms_response(:incoming => "#{form_code} 1.15 2.c", :outgoing => /#{form_code}.+merci/i)
  end
  
  private
    # simulates the reception of an incoming sms by the SmsController and tests the response(s) that is (are) sent back
    def assert_sms_response(params)
      # default to user phone and time of now
      params[:from] ||= @user.phone
      params[:sent_at] ||= Time.now
      
      # ensure :incoming and :outgoing are arrays
      params[:incoming] = Array.wrap(params[:incoming])
      params[:outgoing] = Array.wrap(params[:outgoing])

      # get the request params to match what iSMS would send
      req_params = build_request_params(params)
    
      # set the appropriate user agent header (needed)
      @request.env["User-Agent"] = "MultiModem iSMS/1.41"
      
      # do the post request
      post(:create, req_params)
      
      # number of sms responses should equal the expected number
      assert_equal(params[:outgoing].size, assigns(:sms_responses).size)
      
      # for each sms_response set in the controller, compare it to the outgoing spec
      assigns(:sms_responses).each_with_index do |sms, i|
        # ensure the to matches the from
        assert_equal(params[:from], sms.to.first)
        
        # ensure the body is as expected
        assert_match(params[:outgoing][i], sms.body)
        
        # ensure the body is not missing translations
        assert_no_match(/%\{|translation missing/, sms.body)
      end
    end
    
    # builds the HTTP request parameters to mimic iSMS
    def build_request_params(params)
      # isms doesn't use the + sign
      from = params[:from].gsub("+", "")
      
      # get the xml for the messages
      message_xml = params[:incoming].collect do |body|
        # get time and date in isms style
        date = params[:sent_at].utc.strftime("%y/%m/%d")
        time = params[:sent_at].utc.strftime("%H:%M:%S")
        "<MessageNotification><ModemNumber>2:19525945092</ModemNumber><SenderNumber>#{from}</SenderNumber><Date>#{date}</Date><Time>#{time}</Time>
          <Message>#{body}</Message></MessageNotification>"
      end.join
      
      # build and return
      {
        "username" => configatron.isms_incoming_username,
        "password" => configatron.isms_incoming_password,
        "XMLDATA" => "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><Response>#{message_xml}</Response>"
      }
    end
end