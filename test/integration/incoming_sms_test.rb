require 'test_helper'
require 'sms_forms_test_helper'

class IncomingSmsTest < ActionDispatch::IntegrationTest

  REPLY_VIA_ADAPTER_STYLE_ADAPTER = 'IntelliSms'
  REPLY_VIA_RESPONSE_STYLE_ADAPTER = 'FrontlineSms'

  setup do
    @user = get_user
    setup_form(:questions => %w(integer integer), :required => true)
  end

  test "can accept text answers" do
    setup_form(:questions => %w(text), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.this is a text answer", :outgoing => /#{form_code}.+thank you/i)
  end

  test "can accept long_text answers" do
    setup_form(:questions => %w(long_text), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.this is a text answer that is very very long", :outgoing => /#{form_code}.+thank you/i)
  end

  test "long decimal answers have value truncated" do
    setup_form(:questions => %w(decimal), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.sfsdfsdfsdfsdf",
      :outgoing => /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  test "long integer answers have value truncated" do
    setup_form(:questions => %w(integer), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.sfsdfsdfsdfsdf",
      :outgoing => /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid/)
  end

  test "long select_one should have value truncated" do
    setup_form(:questions => %w(select_one), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.sfsdfsdfsdfsdf",
      :outgoing => /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+not a valid option/)
  end

  test "long select_multiple should have value truncated" do
    setup_form(:questions => %w(select_multiple), :required => true)
    assert_sms_response(:incoming => "#{form_code} 1.sfsdfsdfsdfsdf",
      :outgoing => /Sorry.+answer 'sfsdfsdfsd...'.+question 1.+form '#{form_code}'.+contained multiple invalid options/)
  end

  test "correct message should get congrats" do
    # response should include the form code
    assert_sms_response(:incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
  end

  test "GET submissions should be possible via different endpoint" do
    assert_sms_response(:url => "/m/#{get_mission.compact_name}/sms/submit", :method => :get,
      :incoming => "#{form_code} 1.15 2.20", :outgoing => /#{form_code}.+thank you/i)
  end

  test "message from automated sender should get no response" do
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
    assert_sms_response(:incoming => "#{form_code} 1.21 2.21", :outgoing => /Must be less than or equal to 20/)
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

  test "for reply-via-adapter style incoming adapter, reply should be sent via mission's outgoing adapter" do
    do_incoming_request(:from => '+1234567890', :incoming => {:body => 'foo', :adapter => REPLY_VIA_ADAPTER_STYLE_ADAPTER})
    assert_equal(1, assigns(:outgoing_adapter).deliveries.size)
    assert_equal('REPLY_SENT', @response.body)
  end

  test "for reply-via-response style adapter, reply body should be response body" do
    do_incoming_request(:from => '+1234567890', :incoming => {:body => 'foo', :adapter => REPLY_VIA_RESPONSE_STYLE_ADAPTER})

    # Make sure no messages developed via adatper.
    assert_equal(0, assigns(:outgoing_adapter).deliveries.size)

    # We do an exact equality test since it's key there is no extra junk in response body.
    assert_equal("Sorry, we couldn't find you in the system.", @response.body)
  end

  test "for reply-via-response style adapter, message with no reply should result in empty response" do
    # Non-numeric from number results in no reply.
    do_incoming_request(:from => 'foo', :incoming => {:body => 'foo', :adapter => REPLY_VIA_RESPONSE_STYLE_ADAPTER})
    assert_equal('', @response.body)
    assert_equal(204, @response.status)
  end

  private

    # helper that sets up a new form with the given parameters
    def setup_form(options)
      @form = FactoryGirl.create(:form, :smsable => true, :question_types => options[:questions])
      @form.questionings.each{ |q| q.update_attribute(:required, true) } if options[:required]
      @form.publish!
      @form.reload
    end

    # simulates the reception of an incoming sms by the SmsController and tests the response(s) that is (are) sent back
    def assert_sms_response(params)
      params[:from] ||= @user.phone
      params[:sent_at] ||= Time.now

      # hashify incoming/outgoing if they're not hashes
      params[:incoming] = {:body => params[:incoming]} unless params[:incoming].is_a?(Hash)
      params[:outgoing] = {:body => params[:outgoing]} unless params[:outgoing].is_a?(Hash)

      # default mission to get_mission unless specified
      params[:mission] ||= get_mission

      # do post request based on params
      do_incoming_request(params)
      assert_response(:success)

      # compare the response to the outgoing spec
      sms = assigns(:reply)

      # if there was no reply, check that this was expected
      if sms.nil?
        assert_nil(params[:outgoing][:body])
      else
        assert_instance_of(Sms::Reply, sms)
        # Ensure attribs are appropriate
        assert_equal(params[:from], sms.to)
        assert_match(params[:outgoing][:body], sms.body)
        assert_equal(params[:mission], sms.mission)
        assert_no_match(/%\{|translation missing/, sms.body)
        assert_equal(params[:outgoing][:adapter], sms.adapter_name) if params[:outgoing][:adapter]
      end
    end

    # builds and sends the HTTP POST request to mimic incoming adapter
    def do_incoming_request(params)
      req_params = {}
      req_env = {}

      params[:sent_at] ||= Time.now
      params[:mission] ||= get_mission
      params[:incoming][:adapter] ||= 'IntelliSms'
      params[:url] ||= "/m/#{params[:mission].compact_name}/sms"
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

      else
        raise "Incoming adapter not recognized. Can't build test request"
      end

      # do the get/post/whatever request
      send(params[:method], params[:url], req_params, req_env)
    end
end
