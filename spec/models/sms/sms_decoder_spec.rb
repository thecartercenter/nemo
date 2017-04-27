require "spec_helper"

describe Sms::Decoder, :sms do

  let(:user) { get_user }

  describe "authentication" do
    context "with SMS Authentication enabled" do
      let(:form) { create_form(questions: %w(integer), authenticate_sms: true) }

      it "should work with the correct code provided" do
        auth_code = user.sms_auth_code
        assert_decoding(body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end

      it "should raise an error with an incorrect code provided" do
        auth_code = "n000"
        assert_decoding_fail(body: "#{auth_code} #{form.code} 1.17", error: "user_not_found")
      end

      it "should raise an error if no code is provided" do
        assert_decoding_fail(body: "#{form.code} 1.17", error: "user_not_found")
      end

      it "should lock account after 3 failed attempts", :investigate do
        create_list(:sms_message, Sms::BRUTE_FORCE_LOCKOUT_THRESHOLD, user: user, auth_failed: true, type: "incoming")
        assert_decoding_fail(body: "#{form.code} 1.17", error: "account_locked")
      end

      it "should not lock account if threshold is not reached" do
        safe_interval = (Sms::BRUTE_FORCE_CHECK_WINDOW / Sms::BRUTE_FORCE_LOCKOUT_THRESHOLD) + 1
        Timecop.freeze

        3.times do
          Timecop.travel(safe_interval)
          create(:sms_message, user: user, auth_failed: true, type: "incoming")
        end

        Timecop.travel(safe_interval)
        auth_code = user.sms_auth_code
        assert_decoding(body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end
    end

    context "with SMS Authentication disabled" do
      let(:form) { create_form(questions: %w(integer), authenticate_sms: false) }

      it "should work with the an unnecessary code provided" do
        auth_code = user.sms_auth_code
        assert_decoding(body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end
    end
  end

  describe "form lookup" do
    it "submitting to unpublished form should produce appropriate error" do
      create_form(questions: %w(integer))
      @form.unpublish!
      assert_decoding_fail(body: "#{@form.code} 1.15", error: "form_not_published")
    end

    it "submitting to non-existent form should produce appropriate error" do
      assert_decoding_fail(body: "abc 1.15", error: "form_not_found")
    end

    it "submitting to outdated form should produce appropriate error" do
      create_form(questions: %w(integer))

      # upgrade form version before submitting
      old_version_code = @form.current_version.code
      @form.upgrade_version!

      assert_decoding_fail(body: "#{old_version_code} 1.15", error: "form_version_outdated")
    end

    it "submitting to non-smsable form should produce appropriate error" do
      create_form(questions: %w(integer))

      # turn off smsable before submitting
      @form.unpublish!
      @form.update_attributes!(smsable: false)
      @form.publish!

      assert_decoding_fail(body: "#{@form.code} 1.15", error: "form_not_smsable")
    end

    it "submitting to form without permission should produce appropriate error" do
      create_form(questions: %w(integer))

      # create user with permissions on different mission
      other_mission = create(:mission, name: "OtherMission")
      other_user = create(:user, login: "test2", phone: "+15556667778")
      other_user.assignments.first.update_attributes(mission_id: other_mission.id)
      other_user.reload

      # ensure user doesn't have permission on form
      expect(Ability.new(
        user: other_user,
        mission: other_mission
      ).cannot?(:submit_to, @form)).to be_truthy, "User test2 shouldn't be able to access form."

      # ensure decoding fails due to no permission
      assert_decoding_fail(body: "#{@form.code} 1.15", user: other_user, error: "form_not_permitted")
    end

    it "form code should be case insensitive" do
      create_form(questions: %w(integer))
      assert_decoding(body: "#{@form.code.upcase} 1.15", answers: [15])
    end
  end

  describe "user lookup" do
    it "submitting from phone number without plus sign should work" do
      create_form(questions: %w(integer))
      phone = user.phone.gsub("+", "")
      assert_decoding(body: "#{@form.code} 1.15", from: phone, answers: [15])
    end

    it "submitting from unrecognized phone number should error" do
      create_form(questions: %w(integer))
      assert_decoding_fail(body: "#{@form.code} 1.15", from: "+12737272722", error: "user_not_found")
    end

    it "submitting from phone number with letters should raise special error" do
      create_form(questions: %w(integer))
      assert_decoding_fail(body: "#{@form.code} 1.15", from: "DEALS", error: "automated_sender")
    end

    it "submitting from shortcode should raise special error" do
      create_form(questions: %w(integer))
      assert_decoding_fail(body: "#{@form.code} 1.15", from: "123456", error: "automated_sender")
    end

    it "submitting from second phone number should work" do
      create_form(questions: %w(integer))

      # setup second phone for user
      second_phone = "+12342342342"
      user.phone2 = second_phone
      user.save(validate: false)

      # submit using second number
      assert_decoding(body: "#{@form.code} 1.15", from: second_phone, answers: [15])
    end
  end

  describe "mission lookup and checking" do
    let(:form) { create_form(questions: %w(integer)) }

    context "with mission pre-specified and form in mission" do
      it "succeeds" do
        assert_decoding(body: "#{form.code} 1.15", answers: [15], mission: form.mission)
      end
    end

    context "with mission pre-specified and form from other mission" do
      it "fails with form not found error" do
        assert_decoding_fail(body: "#{form.code} 1.15", mission: create(:mission), error: "form_not_found")
      end
    end

    context "with no mission pre-specified" do
      it "succeeds and sets correct mission on message" do
        assert_decoding(body: "#{form.code} 1.15", answers: [15], mission: nil)
        expect(@msg.reload.mission).not_to be_nil
        expect(@msg.mission).to eq form.mission
      end
    end
  end

  describe "answer parsing" do
    it "form with text question should work" do
      create_form(questions: %w(text integer))
      assert_decoding(body: "#{@form.code} 1.weather is very cold 2.234", answers: ["weather is very cold", 234])
    end

    it "form with long_text question should work" do
      create_form(questions: %w(text integer))
      assert_decoding(
        body: "#{@form.code} 1.weather is very hot and humid with threats of storms 2.4345",
        answers: ["weather is very hot and humid with threats of storms", 4345])
    end

    it "form with single question should work" do
      create_form(questions: %w(integer))
      assert_decoding(body: "#{@form.code} 1.15", answers: [15])
    end

    it "submitting garbage should fail" do
      assert_decoding_fail(body: "lasjdalfksldjal", error: "invalid_form_code")
    end

    it "form with invalid integer should error" do
      create_form(questions: %w(integer))
      assert_decoding_fail(body: "#{@form.code} 1.1d", error: "answer_not_integer", rank: 1, value: "1d")
    end

    it "form with invalid question rank should error" do
      create_form(questions: %w(integer))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.8", error: "question_doesnt_exist", rank: 2)
    end

    it "form with duplicate answers for the same question should error" do
      create_form(questions: %w(integer integer))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.8 2.9", error: "duplicate_answer", rank: 2)
    end

    it "spaces after decimal points should not cause error" do
      create_form(questions: %w(integer integer))
      assert_decoding(body: "#{@form.code} 1. 15 2. 8", answers: [15, 8])
    end

    it "select_one question should work" do
      create_form(questions: %w(integer select_one))
      assert_decoding(body: "#{@form.code} 1.15 2.b", answers: [15, "Banana"])
    end

    it "select_one question with numeric option should error" do
      create_form(questions: %w(integer select_one))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.6", error: "answer_not_valid_option", rank: 2, value: "6")
    end

    it "select_one question with non-existent option should error" do
      create_form(questions: %w(integer select_one))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.h", error: "answer_not_valid_option", rank: 2, value: "h")
    end

    it "select_one question treated as text should work" do
      create_form(questions: %w(integer select_one_as_text_for_sms))
      assert_decoding(body: "#{@form.code} 1.15 2.banana", answers: [15, "Banana"])
    end

    it "select_one question treated as text should work if option name has spaces" do
      create_form(questions: %w(integer select_one_as_text_for_sms integer))
      assert_decoding(body: "#{@form.code} 1.15 2.Elder berry 3.99", answers: [15, "Elder Berry", 99])
    end

    it "select_one question treated as text should not work with normal encoding" do
      create_form(questions: %w(integer select_one_as_text_for_sms))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.b", error: "answer_not_valid_option", rank: 2, value: "b")
    end

    it "select_one question treated as text should not work if no match" do
      create_form(questions: %w(integer select_one_as_text_for_sms))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.Peach", error: "answer_not_valid_option", rank: 2, value: "Peach")
    end

    it "select_one question treated as text should work for multilevel option set" do
      create_form(questions: %w(integer multilevel_select_one_as_text_for_sms), default_option_names: true)
      assert_decoding(body: "#{@form.code} 1.15 2.tulip", answers: [15, ["Plant", "Tulip"]])
    end

    it "select_one question treated as text should work for multilevel option set for non-leaf option" do
      create_form(questions: %w(integer multilevel_select_one_as_text_for_sms), default_option_names: true)
      assert_decoding(body: "#{@form.code} 1.15 2.Plant", answers: [15, ["Plant", "NIL"]])
    end

    it "select_one question with appendix and invalid option should not work", :investigate do
      create_form(questions: %w(integer select_one_with_appendix_for_sms))
      assert_decoding_fail(body: "#{@form.code} 1.15 2.no", error: "answer_not_valid_option")
    end

    it "select_one question with appendix should work" do
      create_form(questions: %w(integer select_one_with_appendix_for_sms))
      assert_decoding(body: "#{@form.code} 1.15 2.2", answers: [15, "Banana"])
    end

    it "option codes should be case insensitive" do
      create_form(questions: %w(integer select_one))
      assert_decoding(body: "#{@form.code} 1.15 2.B", answers: [15, "Banana"])
    end

    it "select_multiple question should work" do
      create_form(questions: %w(integer select_multiple))
      assert_decoding(body: "#{@form.code} 1.15 2.bd", answers: [15, %w(Banana Durian)])
    end

    it "select_multiple question with one numeric option should error" do
      create_form(questions: %w(integer select_multiple))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.b3d",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "b3d", invalid_options: "3")
    end

    it "select_multiple question with one non-existent option should error" do
      create_form(questions: %w(integer select_multiple))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.abh",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "abh", invalid_options: "h")
    end

    it "select_multiple question with several non-existent options should error" do
      create_form(questions: %w(integer select_multiple))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.abhk",
        error: "answer_not_valid_options_multi",
        rank: 2, value: "abhk", invalid_options: "h, k")
    end

    it "select_multiple question with period in option should error" do
      create_form(questions: %w(integer select_multiple))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2..B",
        error: "answer_not_valid_option_multi",
        rank: 2, value: ".b", invalid_options: ".b")
    end

    it "select_multiple question with appendix should work" do
      create_form(questions: %w(integer select_multiple_with_appendix_for_sms))
      assert_decoding(body: "#{@form.code} 1.15 2.2,4", answers: [15, %w(Banana Durian)])
    end

    it "select_multiple question with appendix and one non-existent option should error" do
      create_form(questions: %w(integer select_multiple_with_appendix_for_sms))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.2,4,no",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "2,4,no", invalid_options: "no")
    end

    it "select_multiple question with appendix and several non-existent options should error" do
      create_form(questions: %w(integer select_multiple_with_appendix_for_sms))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.2,no,nope",
        error: "answer_not_valid_options_multi",
        rank: 2, value: "2,no,nope", invalid_options: "no, nope")
    end

    it "select_multiple questions with large option set should work" do
      create_form(questions: %w(integer large_select_multiple))
      assert_decoding(body: "#{@form.code} 1.15 2.11,20,1a", answers: [15, %w(1 36 10)])
    end

    it "select_multiple question with large option set and spaces around commas should work" do
      create_form(questions: %w(integer large_select_multiple))
      assert_decoding(body: "#{@form.code} 1.15 2.11 ,20, 1a", answers: [15, %w(1 36 10)])
    end

    it "select_multiple questions with large option set and no commas should fail" do
      create_form(questions: %w(integer large_select_multiple))
      assert_decoding_fail(
        body: "#{@form.code} 1.15 2.nope",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "nope", invalid_options: "nope")
    end

    it "select_multiple questions with large option set and more than 4 selections should work" do
      create_form(questions: %w(integer large_select_multiple))
      assert_decoding(body: "#{@form.code} 1.15 2.11,12,13,14,15,20,1a", answers: [15, %w(1 2 3 4 5 36 10)])
    end

    it "decimal question should work", :investigate do
      create_form(questions: %w(decimal))
      assert_decoding(body: "#{@form.code} 1.1.15", answers: [1.15])
    end

    it "decimal question without decimal point should work" do
      create_form(questions: %w(decimal))
      assert_decoding(body: "#{@form.code} 1.15", answers: [15])
    end

    it "decimal question with invalid answer should error" do
      create_form(questions: %w(decimal))
      assert_decoding_fail(body: "#{@form.code} 1.15.2.2", error: "answer_not_decimal", rank: 1, value: "15.2.2")
    end

    it "text question at beginning of message should work" do
      create_form(questions: %w(text integer))
      assert_decoding(body: "#{@form.code} 1.foo bar 2.15", answers: ["foo bar", 15])
    end

    it "long_text question at beginning of message should work" do
      create_form(questions: %w(long_text integer))
      assert_decoding(body: "#{@form.code} 1.foo bar that is very long 2.15", answers: ["foo bar that is very long", 15])
    end

    it "text question in middle of message should work" do
      create_form(questions: %w(select_one text integer))
      assert_decoding(body: "#{@form.code} 1.a 2.foo bar 3.15", answers: ["Apple", "foo bar", 15])
    end

    it "long_text question in middle of message should work" do
      create_form(questions: %w(select_one long_text integer))
      assert_decoding(
        body: "#{@form.code} 1.a 2.foo bar that is very long 3.15",
        answers: ["Apple", "foo bar that is very long", 15])
    end

    it "text question at end of message should work" do
      create_form(questions: %w(select_one integer text))
      assert_decoding(body: "#{@form.code} 1.a 2.15 3.foo bar", answers: ["Apple", 15, "foo bar"])
    end

    it "long_text question at end of message should work" do
      create_form(questions: %w(select_one integer long_text))
      assert_decoding(
        body: "#{@form.code} 1.a 2.15 3.foo bar that is very long",
        answers: ["Apple", 15, "foo bar that is very long"])
    end

    it "text question with space after decimal should work" do
      create_form(questions: %w(select_one text integer))
      assert_decoding(body: "#{@form.code} 1.a 2. foo bar 3.15", answers: ["Apple", "foo bar", 15])
    end

    it "weird chunk should error" do
      create_form(questions: %w(select_one text integer))
      assert_decoding_fail(
        body: "#{@form.code} 1.a 2. foo bar 3.15 baz",
        error: "answer_not_integer", rank: 3, value: "15 baz")
    end

    it "date question should work" do
      create_form(questions: %w(integer date))
      assert_decoding(body: "#{@form.code} 1.4 2.20120229", answers: [4, Date.new(2012, 2, 29)])

      # check other formats
      assert_decoding(body: "#{@form.code} 1.4 2.2012/02/29", answers: [4, Date.new(2012, 2, 29)])
      assert_decoding(body: "#{@form.code} 1.4 2.2012.02.29", answers: [4, Date.new(2012, 2, 29)])
      assert_decoding(body: "#{@form.code} 1.4 2.2012.2.29", answers: [4, Date.new(2012, 2, 29)])
    end

    it "date question with invalid date should error" do
      create_form(questions: %w(integer date))
      assert_decoding_fail(body: "#{@form.code} 1.4 2.20120230", error: "answer_not_date", value: "20120230")
    end

    it "date question with too short date should error" do
      create_form(questions: %w(integer date))
      assert_decoding_fail(body: "#{@form.code} 1.4 2.2012230", error: "answer_not_date", value: "2012230")
    end

    it "date question with junk should error" do
      create_form(questions: %w(integer date))
      assert_decoding_fail(body: "#{@form.code} 1.4 2.foobarbaz", error: "answer_not_date", value: "foobarbaz")
    end

    it "time question should work" do
      create_form(questions: %w(integer time))
      assert_decoding(body: "#{@form.code} 1.4 2.1230", answers: [4, Time.parse("2000-01-01 12:30 UTC")])

      # make sure time gets saved properly and zone doesn't mess up
      @response.reload
      expect(@response.answers.last.time_value.hour).to eq(12)

      # check other formats
      assert_decoding(body: "#{@form.code} 1.4 2.12:30", answers: [4, Time.parse("2000-01-01 12:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.12:30pm", answers: [4, Time.parse("2000-01-01 12:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.12:45PM", answers: [4, Time.parse("2000-01-01 12:45 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.12.30pm", answers: [4, Time.parse("2000-01-01 12:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.130", answers: [4, Time.parse("2000-01-01 1:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.0130", answers: [4, Time.parse("2000-01-01 1:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.1:30", answers: [4, Time.parse("2000-01-01 1:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.1:30am", answers: [4, Time.parse("2000-01-01 1:30 UTC")])
      assert_decoding(body: "#{@form.code} 1.4 2.1:30pm", answers: [4, Time.parse("2000-01-01 13:30 UTC")])
    end

    it "invalid times should error" do
      create_form(questions: %w(integer time))
      ["12:300", "25:00", "00000", "12", "abc"].each do |str|
        assert_decoding_fail(body: "#{@form.code} 1.4 2.#{str}", error: "answer_not_time", value: str)
      end
    end

    it "datetime question should work" do
      create_form(questions: %w(integer datetime))

      # use sask b/c no daylight savings
      Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

      assert_decoding(
        body: "#{@form.code} 1.4 2.20120229 1230",
        answers: [4, Time.zone.parse("2012-02-29 12:30")])

      # make sure time gets saved properly and zone doesn't mess up
      @response.reload
      expect(@response.answers.last.datetime_value.hour).to eq(12)

      # make sure timezone gets set properly (Saskatchewan is CST)
      expect(@response.answers.last.datetime_value.zone.to_s).to eq("CST")

      # check other formats
      assert_decoding(body: "#{@form.code} 1.4 2.20120229 230", answers: [4, Time.zone.parse("2012-02-29 2:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.20120229 12:30pm", answers: [4, Time.zone.parse("2012-02-29 12:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.20120229 1:30", answers: [4, Time.zone.parse("2012-02-29 1:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.2012/02/29 12:30pm", answers: [4, Time.zone.parse("2012-02-29 12:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.2012-02-29 12:30pm", answers: [4, Time.zone.parse("2012-02-29 12:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.2012-11-1 12:30pm", answers: [4, Time.zone.parse("2012-11-01 12:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.201211011230", answers: [4, Time.zone.parse("2012-11-01 12:30")])
      assert_decoding(body: "#{@form.code} 1.4 2.201211010230", answers: [4, Time.zone.parse("2012-11-01 2:30")])
    end

    it "invalid datetimes should error" do
      create_form(questions: %w(integer datetime))
      ["2012121212300", "mar 1 2012 2:30", "201212", "891015 12pm", "2-2-2012 5pm"].each do |str|
        assert_decoding_fail(body: "#{@form.code} 1.4 2.#{str}", error: "answer_not_datetime", value: str)
      end
    end

    it "answers for questions in groups should work" do
      create_form(questions: ["integer", %w(text date), "date"])
      assert_decoding(
        body: "#{@form.code} 1.3 2.coffee and bagels 3.20151225 4.20160101",
        answers: [3, "coffee and bagels", Date.new(2015, 12, 25), Date.new(2016, 01, 01)]
      )
    end
  end

  describe "duplicate checking" do
    it "duplicate sent within timeframe should error" do
      create_form(questions: %w(integer))
      assert_decoding(body: "#{@form.code} 1.4", answers: [4])
      Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW - 1.minute) do
        assert_decoding_fail(body: "#{@form.code} 1.4", error: "duplicate_submission")
      end
    end

    it "duplicate sent outside timeframe should not error" do
      create_form(questions: %w(integer))
      assert_decoding(body: "#{@form.code} 1.4", answers: [4])
      Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW + 1.minute) do
        assert_decoding(body: "#{@form.code} 1.4", answers: [4])
      end
    end
  end

  private

  def create_form(options)
    option_names = options[:default_option_names] ? nil : %w(Apple Banana Cherry Durian) + ["Elder Berry"]
    authenticate_sms = options[:authenticate_sms] ? options[:authenticate_sms] : false
    @form = create(:form,
      smsable: true,
      question_types: options[:questions],
      option_names: option_names, authenticate_sms: authenticate_sms)
    @form.publish!
    @form.reload
  end

  # tests that a decoding was successful
  def assert_decoding(options)
    options[:user] ||= user
    options[:mission] = get_mission unless options.has_key?(:mission)
    options[:from] ||= options[:user].phone

    # create the Sms object
    @msg = Sms::Incoming.create(options.slice(:from, :body, :mission))

    # perform the decoding
    @response = Sms::Decoder.new(@msg).decode
    @response.save!

    # if we get this far and were expecting a failure, we didn't get one, so just return
    return if options[:expecting_fail]

    # ensure the form is correct
    expect(@response.form_id).to eq(@form.id)

    nodes = AnswerArranger.new(@response).build.leaf_nodes

    # ensure an expected answer was given for this question
    expect(options[:answers].size >= nodes.size).to be_truthy,
      "No expected answer was given for question #{nodes.size + 1}"

    # ensure the answers match the expected ones
    @form.questionings.each_with_index do |qing, i|
      node = nodes[i]

      expect(node.item).to eq(qing), "Missing answer at index #{i}"

      # copy the expected value
      expected = options[:answers][i]

      # replace the array index with nil so that we know this one has been looked at
      options[:answers][i] = nil

      ansset = node.set

      # ensure answer matches
      case qing.qtype_name
      when "integer"
        expect(ansset.value.to_i).to eq(expected)
      when "decimal"
        expect(ansset.value.to_f).to eq(expected)
      when "select_one"
        # for select one, the expected value is the english translation(s) of the desired option(s)
        expect(ansset.answers.map { |a| a.option.try(:name_en) || "NIL" }).to eq(Array.wrap(expected))
        # Check answer ranks.
        if qing.multilevel?
          expect(ansset.answers.map(&:rank)).to eq((1..expected.size).to_a), "Invalid answer ranks"
        else
          expect(ansset.first.rank).to eq(1), "Answer rank should be 1"
        end
      when "select_multiple"
        # for select multiple, the expected value is an array of the english translations of the desired options
        expect(ansset.choices.collect { |c| c.option.name_en }).to eq(expected)
      when "text", "long_text"
        expect(ansset.value).to eq(expected)
      when "date"
        expect(ansset.date_value).to eq(expected)
      when "time"
        expect(ansset.time_value).to eq(expected)
      when "datetime"
        expect(ansset.datetime_value).to eq(expected)
      else
        raise "Unexpected type"
      end
    end

    # check that all expected answers have been looked at (they should all be nil)
    options[:answers].each_with_index do |a, i|
      expect(a).to be_nil, "No answer was given for question #{i+1}"
    end
  end

  # tests that a decoding fails
  def assert_decoding_fail(options)
    error = nil
    begin
      assert_decoding(options.merge(expecting_fail: true))
    rescue Sms::DecodingError
      error = $!
    end

    # ensure error of appropriate type was raised
    expect(error).not_to be_nil, "No error was raised"

    # ensure error params are correct
    expect(error.type).to eq(options[:error])
    expect(error.params[:rank]).to eq(options[:rank]) if options[:rank]
    expect(error.params[:value]).to eq(options[:value]) if options[:value]
  end
end
