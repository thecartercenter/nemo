require 'test_helper'

class SmsDecoderTest < ActiveSupport::TestCase
  
  setup do
    QuestionType.generate
    [Form, Question, Questioning, Option, OptionSet, OptionSetting, Response].each{|k| k.delete_all}
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
    assert(!Permission.user_can_submit_to_form(other_user, @form), "User test2 shouldn't be able to access form.")
    
    # ensure decoding fails due to no permission
    assert_decoding_fail(:body => "#{form_code} 1.15", :user => other_user, :error => "form_not_permitted")
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
  
  test "select_one question should work" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding(:body => "#{form_code} 1.15 2.b", :answers => [15, "B"])
  end

  test "select_one question with numeric option should error" do
    setup_form(:questions => %w(integer select_one))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.6", :error => "answer_not_option_letter", :rank => 2, :value => "6")
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
    assert_decoding_fail(:body => "#{form_code} 1.15 2.b3d", :error => "answer_not_option_letter_multi", :rank => 2, :value => "b3d")
  end

  test "select_multiple question with one non-existent option should error" do
    setup_form(:questions => %w(integer select_multiple))
    assert_decoding_fail(:body => "#{form_code} 1.15 2.abh", :error => "answer_not_valid_option_multi", :rank => 2, :value => "h")
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

  
  
  # test weird stuff
  # date types with separators should work
  # date types without separators should work
  # tiny text question should work
  # tiny text question followed by another question should work

  private
    # helper that sets up a new form with the given parameters
    def setup_form(options)
      @form = FactoryGirl.create(:form, :smsable => true)
      options[:questions].each do |type|
        # create the question
        q = FactoryGirl.build(:question, :question_type_id => QuestionType.find_by_name(type).id)
        
        # add an option set if required
        if %w(select_one select_multiple).include?(type)
          q.option_set = FactoryGirl.create(:option_set, :name => "Options", :option_names => %w(A B C D E))
        end

        q.save!
        
        # add it to the form
        @form.questionings.create(:question => q)
      end
      @form.publish!
      @form.reload
    end
    
    # tests that a decoding was successful
    def assert_decoding(options)
      options[:user] ||= @user

      # create the Sms object
      msg = Sms::Message.new(:direction => :incoming, :from => options[:from] || options[:user].phone, :body => options[:body])
      
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
        case ans.questioning.question.type.name
        when "integer"
          assert_equal(expected, ans.value.to_i)
        when "select_one"
          # for select one, the expected value is the english translation of the desired option
          assert_equal(expected, ans.option.name_eng)
        when "select_multiple"
          # for select multiple, the expected value is an array of the english translations of the desired options
          assert_equal(expected, ans.choices.collect{|c| c.option.name_eng})
        end
      end
      
      # check that all expected answers have been looked at (they should all be nil)
      options[:answers].each_with_index do |a, i|
        assert_nil(a, "No answer was given for question #{i+1}")
      end
      
      # ensure that saving the response works
      response.save!
    end
    
    # tests that a decoding fails
    def assert_decoding_fail(options)
      error = nil
      begin
        assert_decoding(options.merge(:expecting_fail => true))
      rescue Sms::Error
        error = $!
      end
      
      # ensure error of appropriate type was raised
      assert_not_nil(error, "No error was raised")
      
      # ensure error params are correct
      assert_equal(options[:error], error.message)
      assert_equal(options[:rank], error.params[:rank]) if options[:rank]
      assert_equal(options[:value], error.params[:value]) if options[:value]
    end
    
    # gets the version code for the current form
    def form_code
      @form.current_version.code
    end
end