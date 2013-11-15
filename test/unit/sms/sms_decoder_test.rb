require 'test_helper'
require 'sms_forms_test_helper'

class SmsDecoderTest < ActiveSupport::TestCase
  
  setup do
    @user = get_user
  end
  
  test "form with single question should work" do
    setup_form(:questions => %w(integer))
    assert_decoding(:body => "#{form_code} 1.15", :answers => [15])
  end

  test "submitting garbage should fail" do
    assert_decoding_fail(:body => "lasjdalfksldjal", :error => "invalid_form_code")
  end

  test "submitting to unpublished form should produce appropriate error" do
    setup_form(:questions => %w(integer))

    # unpublish the form and then submit
    @form.unpublish!
    
    assert_decoding_fail(:body => "#{form_code} 1.15", :error => "form_not_published")
  end
  
  test "submitting to non-existent form should produce appropriate error" do
    assert_decoding_fail(:body => "abc 1.15", :error => "form_not_found")
  end
  
  test "submitting to outdated form should produce appropriate error" do
    setup_form(:questions => %w(integer))
    
    # upgrade form version before submitting
    old_version_code = @form.current_version.code
    @form.upgrade_version!
    
    assert_decoding_fail(:body => "#{old_version_code} 1.15", :error => "form_version_outdated")
  end
  
  test "submitting to non-smsable form should produce appropriate error" do
    setup_form(:questions => %w(integer))
    
    # turn off smsable before submitting
    @form.unpublish!
    @form.update_attributes!(:smsable => false)
    @form.publish!
    
    assert_decoding_fail(:body => "#{form_code} 1.15", :error => "form_not_smsable")
  end
  
  test "submitting to form without permission should produce appropriate error" do
    setup_form(:questions => %w(integer))
    
    # create user with permissions on different mission
    other_mission = FactoryGirl.create(:mission, :name => "OtherMission")
    other_user = FactoryGirl.create(:user, :login => "test2", :phone => "+15556667778")
    other_user.assignments.first.update_attributes(:mission_id => other_mission.id)
    other_user.reload
    
    # ensure user doesn't have permission on form
    assert(!other_user.can?(:submit_to, @form), "User test2 shouldn't be able to access form.")
    
    # ensure decoding fails due to no permission
    assert_decoding_fail(:body => "#{form_code} 1.15", :user => other_user, :error => "form_not_permitted")
  end
  
  test "submitting from phone number without plus sign should work" do
    setup_form(:questions => %w(integer))
    phone = @user.phone.gsub("+", "")
    assert_decoding(:body => "#{form_code} 1.15", :from => phone, :answers => [15])
  end

  test "submitting from unrecognized phone number should error" do
    setup_form(:questions => %w(integer))
    assert_decoding_fail(:body => "#{form_code} 1.15", :from => "+12737272722", :error => "user_not_found")
  end

  test "submitting from second phone number should work" do
    setup_form(:questions => %w(integer))
    
    # setup second phone for user
    second_phone = "+12342342342"
    @user.phone2 = second_phone
    @user.save(:validate => false)
    
    # submit using second number
    assert_decoding(:body => "#{form_code} 1.15", :from => second_phone, :answers => [15])
  end  

  test "form code should be case insensitive" do
    setup_form(:questions => %w(integer))
    assert_decoding(:body => "#{form_code.upcase} 1.15", :answers => [15])
  end

  test "form with invalid integer should error" do
    setup_form(:questions => %w(integer))
    assert_decoding_fail(:body => "#{form_code} 1.1d", :error => "answer_not_integer", :rank => 1, :value => "1d")
  end
  
  test "form with invalid question rank should error" do
    setup_form(:questions => %w(integer))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.8", :error => "question_doesnt_exist", :rank => 2)
  end
  
  test "spaces after decimal points should not cause error" do
    setup_form(:questions => %w(integer integer))
    assert_decoding(:body => "#{form_code} 1. 15 2. 8", :answers => [15, 8])
  end
  
  test "select_one question should work" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding(:body => "#{form_code} 1.15 2.b", :answers => [15, "B"])
  end

  test "select_one question with numeric option should error" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.6", :error => "answer_not_valid_option", :rank => 2, :value => "6")
  end
  
  test "select_one question with non-existent option should error" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.h", :error => "answer_not_valid_option", :rank => 2, :value => "h")
  end
  
  test "option codes should be case insensitive" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding(:body => "#{form_code} 1.15 2.B", :answers => [15, "B"])
  end
  
  test "select_multiple question should work" do
    setup_form(:questions => %w(integer select_multiple))
    assert_decoding(:body => "#{form_code} 1.15 2.bd", :answers => [15, %w(B D)])
  end

  test "select_multiple question with one numeric option should error" do
    setup_form(:questions => %w(integer select_multiple))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.b3d", :error => "answer_not_valid_option_multi", 
      :rank => 2, :value => "b3d", :invalid_options => "3")
  end

  test "select_multiple question with one non-existent option should error" do
    setup_form(:questions => %w(integer select_multiple))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.abh", :error => "answer_not_valid_option_multi", 
      :rank => 2, :value => "abh", :invalid_options => "h")
  end
  
  test "select_multiple question with several non-existent options should error" do
    setup_form(:questions => %w(integer select_multiple))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.abhk", :error => "answer_not_valid_options_multi", 
      :rank => 2, :value => "abhk", :invalid_options => "h, k")
  end
  
  test "decimal question should work" do
    setup_form(:questions => %w(decimal))
    assert_decoding(:body => "#{form_code} 1.1.15", :answers => [1.15])
  end

  test "decimal question without decimal point should work" do
    setup_form(:questions => %w(decimal))
    assert_decoding(:body => "#{form_code} 1.15", :answers => [15])
  end

  test "decimal question with invalid answer should error" do
    setup_form(:questions => %w(decimal))
    assert_decoding_fail(:body => "#{form_code} 1.15.2.2", :error => "answer_not_decimal", :rank => 1, :value => "15.2.2")
  end

  test "tiny text question at beginning of message should work" do
    setup_form(:questions => %w(tiny_text integer))
    assert_decoding(:body => "#{form_code} 1.foo bar 2.15", :answers => ["foo bar", 15])
  end
  
  test "tiny text question in middle of message should work" do
    setup_form(:questions => %w(select_one tiny_text integer))
    assert_decoding(:body => "#{form_code} 1.a 2.foo bar 3.15", :answers => ["A", "foo bar", 15])
  end

  test "tiny text question at end of message should work" do
    setup_form(:questions => %w(select_one integer tiny_text))
    assert_decoding(:body => "#{form_code} 1.a 2.15 3.foo bar", :answers => ["A", 15, "foo bar"])
  end
  
  test "tiny text question with space after decimal should work" do
    setup_form(:questions => %w(select_one tiny_text integer))
    assert_decoding(:body => "#{form_code} 1.a 2. foo bar 3.15", :answers => ["A", "foo bar", 15])
  end
  
  test "weird chunk should error" do 
    setup_form(:questions => %w(select_one tiny_text integer))
    assert_decoding_fail(:body => "#{form_code} 1.a 2. foo bar 3.15 baz", :error => "answer_not_integer", :rank => 3, :value => "15 baz")
  end
  
  test "date question should work" do
    setup_form(:questions => %w(integer date))
    assert_decoding(:body => "#{form_code} 1.4 2.20120229", :answers => [4, Date.new(2012, 2, 29)])
    
    # check other formats
    assert_decoding(:body => "#{form_code} 1.4 2.2012/02/29", :answers => [4, Date.new(2012, 2, 29)])
    assert_decoding(:body => "#{form_code} 1.4 2.2012.02.29", :answers => [4, Date.new(2012, 2, 29)])
    assert_decoding(:body => "#{form_code} 1.4 2.2012.2.29", :answers => [4, Date.new(2012, 2, 29)])
  end

  test "date question with invalid date should error" do
    setup_form(:questions => %w(integer date))
    assert_decoding_fail(:body => "#{form_code} 1.4 2.20120230", :error => "answer_not_date", :value => "20120230")
  end
  
  test "date question with too short date should error" do
    setup_form(:questions => %w(integer date))
    assert_decoding_fail(:body => "#{form_code} 1.4 2.2012230", :error => "answer_not_date", :value => "2012230")
  end

  test "date question with junk should error" do
    setup_form(:questions => %w(integer date))
    assert_decoding_fail(:body => "#{form_code} 1.4 2.foobarbaz", :error => "answer_not_date", :value => "foobarbaz")
  end

  test "time question should work" do
    setup_form(:questions => %w(integer time))
    response = assert_decoding(:body => "#{form_code} 1.4 2.1230", :answers => [4, Time.parse("12:30 UTC")])

    # make sure time gets saved properly and zone doesn't mess up
    response.reload
    assert_equal(12, response.answers.last.time_value.hour)
    
    # check other formats
    assert_decoding(:body => "#{form_code} 1.4 2.12:30", :answers => [4, Time.parse("12:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.12:30pm", :answers => [4, Time.parse("12:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.12:45PM", :answers => [4, Time.parse("12:45 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.12.30pm", :answers => [4, Time.parse("12:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.130", :answers => [4, Time.parse("1:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.0130", :answers => [4, Time.parse("1:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.1:30", :answers => [4, Time.parse("1:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.1:30am", :answers => [4, Time.parse("1:30 UTC")])
    assert_decoding(:body => "#{form_code} 1.4 2.1:30pm", :answers => [4, Time.parse("13:30 UTC")])
  end
  
  test "invalid times should error" do
    setup_form(:questions => %w(integer time))
    ["12:300", "25:00", "00000", "12", "abc"].each do |str|
      assert_decoding_fail(:body => "#{form_code} 1.4 2.#{str}", :error => "answer_not_time", :value => str)
    end
  end
  
  test "datetime question should work" do 
    setup_form(:questions => %w(integer datetime))
    
    # use sask b/c no daylight savings
    Time.zone = ActiveSupport::TimeZone["Saskatchewan"]
    
    response = assert_decoding(:body => "#{form_code} 1.4 2.20120229 1230", :answers => [4, Time.zone.parse("2012-02-29 12:30")])
    
    # make sure time gets saved properly and zone doesn't mess up
    response.reload
    assert_equal(12, response.answers.last.datetime_value.hour)
    
    # make sure timezone gets set properly (Saskatchewan is CST)
    assert_equal("CST", response.answers.last.datetime_value.zone.to_s)
    
    # check other formats
    assert_decoding(:body => "#{form_code} 1.4 2.20120229 230", :answers => [4, Time.zone.parse("2012-02-29 2:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.20120229 12:30pm", :answers => [4, Time.zone.parse("2012-02-29 12:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.20120229 1:30", :answers => [4, Time.zone.parse("2012-02-29 1:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.2012/02/29 12:30pm", :answers => [4, Time.zone.parse("2012-02-29 12:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.2012-02-29 12:30pm", :answers => [4, Time.zone.parse("2012-02-29 12:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.2012-11-1 12:30pm", :answers => [4, Time.zone.parse("2012-11-01 12:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.201211011230", :answers => [4, Time.zone.parse("2012-11-01 12:30")])
    assert_decoding(:body => "#{form_code} 1.4 2.201211010230", :answers => [4, Time.zone.parse("2012-11-01 2:30")])
  end
  
  test "invalid datetimes should error" do 
    setup_form(:questions => %w(integer datetime))
    ["2012121212300", "mar 1 2012 2:30", "201212", "891015 12pm", "2-2-2012 5pm"].each do |str|
      assert_decoding_fail(:body => "#{form_code} 1.4 2.#{str}", :error => "answer_not_datetime", :value => str)
    end
  end
  
  test "duplicate sent within timeframe should error" do
    setup_form(:questions => %w(integer))
    assert_decoding(:body => "#{form_code} 1.4", :answers => [4])
    Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW - 1.minute) do
      assert_decoding_fail(:body => "#{form_code} 1.4", :error => "duplicate_submission")
    end
  end

  test "duplicate sent outside timeframe should not error" do
    setup_form(:questions => %w(integer))
    assert_decoding(:body => "#{form_code} 1.4", :answers => [4])
    Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW + 1.minute) do
      assert_decoding(:body => "#{form_code} 1.4", :answers => [4])
    end
  end
  
  test "user submitting without active mission should still work" do
    @user.update_attributes!(:current_mission => nil)
    setup_form(:questions => %w(integer))
    assert_decoding(:body => "#{form_code} 1.15", :answers => [15])
  end
  
  private
    
    # tests that a decoding was successful
    def assert_decoding(options)
      options[:user] ||= @user

      # create the Sms object
      msg = Sms::Message.create(:from => options[:from] || options[:user].phone, :body => options[:body], :mission => get_mission)
      
      # perform the deocding
      response = Sms::Decoder.new(msg).decode
      
      # if we get this far and were expecting a failure, we didn't get one, so just return
      return if options[:expecting_fail]
      
      # ensure the form is correct
      assert_equal(@form.id, response.form_id)
      
      # ensure the answers match the expected ones
      response.answers.each do |ans|
        # ensure an expected answer was given for this question
        assert(options[:answers].size >= ans.questioning.rank, "No expected answer was given for question #{ans.questioning.rank}")
        
        # copy the expected value
        expected = options[:answers][ans.questioning.rank - 1]
        
        # replace the array index with nil so that we know this one has been looked at
        options[:answers][ans.questioning.rank - 1] = nil
        
        # ensure answer matches
        case ans.questioning.question.qtype.name
        when "integer" 
          assert_equal(expected, ans.value.to_i)
        when "decimal"
          assert_equal(expected, ans.value.to_f)
        when "select_one"
          # for select one, the expected value is the english translation of the desired option
          assert_equal(expected, ans.option.name_en)
        when "select_multiple"
          # for select multiple, the expected value is an array of the english translations of the desired options
          assert_equal(expected, ans.choices.collect{|c| c.option.name_en})
        when "tiny_text"
          assert_equal(expected, ans.value)
        when "date"
          assert_equal(expected, ans.date_value)
        when "time"
          assert_equal(expected, ans.time_value)
        when "datetime"
          assert_equal(expected, ans.datetime_value)
        else
          raise "Unexpected type"
        end
      end
      
      # check that all expected answers have been looked at (they should all be nil)
      options[:answers].each_with_index do |a, i|
        assert_nil(a, "No answer was given for question #{i+1}")
      end
      
      # ensure that saving the response works
      response.save!
      
      return response
    end
    
    # tests that a decoding fails
    def assert_decoding_fail(options)
      error = nil
      begin
        assert_decoding(options.merge(:expecting_fail => true))
      rescue Sms::DecodingError
        error = $!
      end
      
      # ensure error of appropriate type was raised
      assert_not_nil(error, "No error was raised")
      
      # ensure error params are correct
      assert_equal(options[:error], error.type)
      assert_equal(options[:rank], error.params[:rank]) if options[:rank]
      assert_equal(options[:value], error.params[:value]) if options[:value]
    end
end