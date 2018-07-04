# frozen_string_literal: true

require "rails_helper"

describe Sms::Decoder, :sms do
  include_context "response tree"

  let(:user) { get_user }

  describe "authentication" do
    context "with SMS Authentication enabled" do
      let(:form) { create_form(questions: %w[integer], authenticate_sms: true) }

      it "should work with the correct code provided" do
        auth_code = user.sms_auth_code
        expect_decoding(form, body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end

      it "should raise an error with an incorrect code provided" do
        auth_code = "n000"
        expect_decoding_fail(form, body: "#{auth_code} #{form.code} 1.17", error: "user_not_found")
      end

      it "should raise an error if no code is provided" do
        expect_decoding_fail(form, data: "1.17", error: "user_not_found")
      end

      it "should lock account after 3 failed attempts" do
        create_list(:sms_message, Sms::BRUTE_FORCE_LOCKOUT_THRESHOLD,
          user: user, auth_failed: true, type: "incoming")
        expect_decoding_fail(form, data: "1.17", error: "account_locked")
      end

      it "should not lock account if threshold is not reached" do
        safe_interval = (Sms::BRUTE_FORCE_CHECK_WINDOW.seconds / Sms::BRUTE_FORCE_LOCKOUT_THRESHOLD) + 1
        Timecop.freeze

        3.times do
          Timecop.travel(safe_interval)
          create(:sms_message, user: user, auth_failed: true, type: "incoming")
        end

        Timecop.travel(safe_interval)
        auth_code = user.sms_auth_code
        expect_decoding(form, body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end
    end

    context "with SMS Authentication disabled" do
      let(:form) { create_form(questions: %w[integer], authenticate_sms: false) }

      it "should work with the an unnecessary code provided" do
        auth_code = user.sms_auth_code
        expect_decoding(form, body: "#{auth_code} #{form.code} 1.17", answers: [17])
      end
    end
  end

  describe "form lookup" do
    it "submitting to unpublished form should produce appropriate error" do
      form = create_form(questions: %w[integer])
      form.unpublish!
      expect_decoding_fail(form, data: "1.15", error: "form_not_published")
    end

    it "submitting to non-existent form should produce appropriate error" do
      expect_decoding_fail(nil, body: "abc 1.15", error: "form_not_found")
    end

    it "submitting to outdated form should produce appropriate error" do
      form = create_form(questions: %w[integer])

      # upgrade form version before submitting
      old_version_code = form.current_version.code
      form.upgrade_version!

      expect_decoding_fail(form, body: "#{old_version_code} 1.15", error: "form_version_outdated")
    end

    it "submitting to non-smsable form should produce appropriate error" do
      form = create_form(questions: %w[integer])

      # turn off smsable before submitting
      form.unpublish!
      form.update!(smsable: false)
      form.publish!

      expect_decoding_fail(form, data: "1.15", error: "form_not_smsable")
    end

    it "submitting to form without permission should produce appropriate error" do
      form = create_form(questions: %w[integer])

      # create user with permissions on different mission
      other_mission = create(:mission, name: "OtherMission")
      other_user = create(:user, login: "test2", phone: "+15556667778")
      other_user.assignments.first.update(mission_id: other_mission.id)
      other_user.reload

      # ensure user doesn't have permission on form
      expect(Ability.new(
        user: other_user,
        mission: other_mission
      ).cannot?(:submit_to, form)).to be_truthy, "User test2 shouldn't be able to access form."

      # ensure decoding fails due to no permission
      expect_decoding_fail(form, data: "1.15", user: other_user, error: "form_not_permitted")
    end

    it "form code should be case insensitive" do
      form = create_form(questions: %w[integer])
      expect_decoding(form, body: "#{form.code.upcase} 1.15", answers: [15])
    end
  end

  describe "user lookup" do
    it "submitting from phone number without plus sign should work" do
      form = create_form(questions: %w[integer])
      phone = user.phone.delete("+")
      expect_decoding(form, data: "1.15", from: phone, answers: [15])
    end

    it "submitting from unrecognized phone number should error" do
      form = create_form(questions: %w[integer])
      expect_decoding_fail(form, data: "1.15", from: "+12737272722", error: "user_not_found")
    end

    it "submitting from phone number with letters should raise special error" do
      form = create_form(questions: %w[integer])
      expect_decoding_fail(form, data: "1.15", from: "DEALS", error: "automated_sender")
    end

    it "submitting from shortcode should raise special error" do
      form = create_form(questions: %w[integer])
      expect_decoding_fail(form, data: "1.15", from: "123456", error: "automated_sender")
    end

    it "submitting from second phone number should work" do
      form = create_form(questions: %w[integer])

      # setup second phone for user
      second_phone = "+12342342342"
      user.phone2 = second_phone
      user.save(validate: false)

      # submit using second number
      expect_decoding(form, data: "1.15", from: second_phone, answers: [15])
    end
  end

  describe "mission lookup and checking" do
    let(:form) { create_form(questions: %w[integer]) }

    context "with mission pre-specified and form in mission" do
      it "succeeds" do
        expect_decoding(form, data: "1.15", answers: [15], mission: form.mission)
      end
    end

    context "with mission pre-specified and form from other mission" do
      it "fails with form not found error" do
        expect_decoding_fail(form, data: "1.15", mission: create(:mission), error: "form_not_found")
      end
    end

    context "with no mission pre-specified" do
      context "with valid input" do
        it "succeeds and sets correct mission on message" do
          expect_decoding(form, data: "1.15", answers: [15], mission: nil)
          expect(Sms::Incoming.first.mission).to eq(form.mission)
        end
      end

      context "from automated sender" do
        it "raises appropriate error" do
          form = create_form(questions: %w[integer])
          # Deliberately use a 4 letter word to start message because it looks like an auth code.
          expect_decoding_fail(form, body: "good deal 4 u", from: "VODACOM",
                                     mission: nil, error: "automated_sender")
        end
      end
    end
  end

  describe "answer parsing" do
    it "form with text question should work" do
      form = create_form(questions: %w[text integer])
      expect_decoding(form, data: "1.weather is very cold 2.234",
                            answers: ["weather is very cold", 234])
    end

    it "form with long_text question should work" do
      form = create_form(questions: %w[text integer])
      expect_decoding(form,
        data: "1.weather is very hot and humid with threats of storms 2.4345",
        answers: ["weather is very hot and humid with threats of storms", 4345])
    end

    it "form with single question should work" do
      form = create_form(questions: %w[integer])
      expect_decoding(form, data: "1.15", answers: [15])
    end

    it "submitting garbage should fail" do
      expect_decoding_fail(nil, body: "lasjdalfksldjal", error: "invalid_form_code")
    end

    it "form with invalid integer should error" do
      form = create_form(questions: %w[integer])
      expect_decoding_fail(form, data: "1.1d", error: "answer_not_integer", rank: 1, value: "1d")
    end

    it "form with invalid question rank should error" do
      form = create_form(questions: %w[integer])
      expect_decoding_fail(form, data: "1.15 2.8", error: "question_doesnt_exist", rank: 2)
    end

    it "form with duplicate answers for the same question should error" do
      form = create_form(questions: %w[integer integer])
      expect_decoding_fail(form, data: "1.15 2.8 2.9", error: "duplicate_answer", rank: 2)
    end

    it "spaces after decimal points should not cause error" do
      form = create_form(questions: %w[integer integer])
      expect_decoding(form, data: "1. 15 2. 8", answers: [15, 8])
    end

    it "select_one question should work" do
      form = create_form(questions: %w[integer select_one])
      expect_decoding(form, data: "1.15 2.b", answers: [15, "Banana"])
    end

    it "select_one question with numeric option should error" do
      form = create_form(questions: %w[integer select_one])
      expect_decoding_fail(form, data: "1.15 2.6", error: "answer_not_valid_option", rank: 2, value: "6")
    end

    it "select_one question with non-existent option should error" do
      form = create_form(questions: %w[integer select_one])
      expect_decoding_fail(form, data: "1.15 2.h", error: "answer_not_valid_option", rank: 2, value: "h")
    end

    it "select_one question treated as text should work" do
      form = create_form(questions: %w[integer select_one_as_text_for_sms])
      expect_decoding(form, data: "1.15 2.banana", answers: [15, "Banana"])
    end

    it "select_one question treated as text should work if option name has spaces" do
      form = create_form(questions: %w[integer select_one_as_text_for_sms integer])
      expect_decoding(form, data: "1.15 2.Elder berry 3.99", answers: [15, "Elder Berry", 99])
    end

    it "select_one question treated as text should not work with normal encoding" do
      form = create_form(questions: %w[integer select_one_as_text_for_sms])
      expect_decoding_fail(form, data: "1.15 2.b", error: "answer_not_valid_option", rank: 2, value: "b")
    end

    it "select_one question treated as text should not work if no match" do
      form = create_form(questions: %w[integer select_one_as_text_for_sms])
      expect_decoding_fail(form, data: "1.15 2.Peach", error: "answer_not_valid_option",
                                 rank: 2, value: "Peach")
    end

    it "select_one question treated as text should work for multilevel option set" do
      form = create_form(questions: %w[integer multilevel_select_one_as_text_for_sms],
                         default_option_names: true)
      response = create_response(form, data: "1.15 2.tulip")

      expect_children(
        response.root_node,
        %w[Answer AnswerSet],
        form.c.map(&:id),
        [15, nil]
      )
      expect_children(
        response.c[1],
        %w[Answer Answer],
        [form.c[1].id] * 2,
        %w[Plant Tulip]
      )
    end

    it "select_one question treated as text should work for multilevel option set for non-leaf option" do
      form = create_form(questions: %w[integer multilevel_select_one_as_text_for_sms],
                         default_option_names: true)
      response = create_response(form, data: "1.15 2.Plant")

      expect_children(
        response.root_node,
        %w[Answer AnswerSet],
        form.c.map(&:id),
        [15, nil]
      )
      expect_children(
        response.c[1],
        %w[Answer],
        [form.c[1].id],
        %w[Plant]
      )
    end

    it "select_one question with appendix and invalid option should not work" do
      form = create_form(questions: %w[integer select_one_with_appendix_for_sms])
      expect_decoding_fail(form, data: "1.15 2.no", error: "answer_not_valid_option")
    end

    it "select_one question with appendix should work" do
      form = create_form(questions: %w[integer select_one_with_appendix_for_sms])
      expect_decoding(form, data: "1.15 2.2", answers: [15, "Banana"])
    end

    it "option codes should be case insensitive" do
      form = create_form(questions: %w[integer select_one])
      expect_decoding(form, data: "1.15 2.B", answers: [15, "Banana"])
    end

    it "select_multiple question should work" do
      form = create_form(questions: %w[integer select_multiple])
      expect_decoding(form, data: "1.15 2.bd", answers: [15, "Banana;Durian"])
    end

    it "select_multiple question with one numeric option should error" do
      form = create_form(questions: %w[integer select_multiple])
      expect_decoding_fail(form,
        data: "1.15 2.b3d",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "b3d", invalid_options: "3")
    end

    it "select_multiple question with one non-existent option should error" do
      form = create_form(questions: %w[integer select_multiple])
      expect_decoding_fail(form,
        data: "1.15 2.abh",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "abh", invalid_options: "h")
    end

    it "select_multiple question with several non-existent options should error" do
      form = create_form(questions: %w[integer select_multiple])
      expect_decoding_fail(form,
        data: "1.15 2.abhk",
        error: "answer_not_valid_options_multi",
        rank: 2, value: "abhk", invalid_options: "h, k")
    end

    it "select_multiple question with period in option should error" do
      form = create_form(questions: %w[integer select_multiple])
      expect_decoding_fail(form,
        data: "1.15 2..B",
        error: "answer_not_valid_option_multi",
        rank: 2, value: ".b", invalid_options: ".b")
    end

    it "select_multiple question with appendix should work" do
      form = create_form(questions: %w[integer select_multiple_with_appendix_for_sms])
      expect_decoding(form, data: "1.15 2.2,4", answers: [15, "Banana;Durian"])
    end

    it "select_multiple question with appendix and one non-existent option should error" do
      form = create_form(questions: %w[integer select_multiple_with_appendix_for_sms])
      expect_decoding_fail(form,
        data: "1.15 2.2,4,no",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "2,4,no", invalid_options: "no")
    end

    it "select_multiple question with appendix and several non-existent options should error" do
      form = create_form(questions: %w[integer select_multiple_with_appendix_for_sms])
      expect_decoding_fail(form,
        data: "1.15 2.2,no,nope",
        error: "answer_not_valid_options_multi",
        rank: 2, value: "2,no,nope", invalid_options: "no, nope")
    end

    it "select_multiple questions with large option set should work" do
      form = create_form(questions: %w[integer large_select_multiple])
      expect_decoding(form, data: "1.15 2.11,20,1a", answers: [15, "1;10;36"])
    end

    it "select_multiple question with large option set and spaces around commas should work" do
      form = create_form(questions: %w[integer large_select_multiple])
      expect_decoding(form, data: "1.15 2.11 ,20, 1a", answers: [15, "1;10;36"])
    end

    it "select_multiple questions with large option set and no commas should fail" do
      form = create_form(questions: %w[integer large_select_multiple])
      expect_decoding_fail(form,
        data: "1.15 2.nope",
        error: "answer_not_valid_option_multi",
        rank: 2, value: "nope", invalid_options: "nope")
    end

    it "select_multiple questions with large option set and more than 4 selections should work" do
      form = create_form(questions: %w[integer large_select_multiple])
      expect_decoding(form, data: "1.15 2.11,12,13,14,15,20,1a", answers: [15, "1;10;2;3;36;4;5"])
    end

    it "counter question should work" do
      form = create_form(questions: %w[counter])
      expect_decoding(form, data: "1.7", answers: [7])
    end

    it "decimal question should work" do
      form = create_form(questions: %w[decimal])
      expect_decoding(form, data: "1.1.15", answers: [1.15])
    end

    it "decimal question without decimal point should work" do
      form = create_form(questions: %w[decimal])
      expect_decoding(form, data: "1.15", answers: [15])
    end

    it "decimal question with invalid answer should error" do
      form = create_form(questions: %w[decimal])
      expect_decoding_fail(form, data: "1.15.2.2", error: "answer_not_decimal", rank: 1, value: "15.2.2")
    end

    it "text question at beginning of message should work" do
      form = create_form(questions: %w[text integer])
      expect_decoding(form, data: "1.foo bar 2.15", answers: ["foo bar", 15])
    end

    it "long_text question at beginning of message should work" do
      form = create_form(questions: %w[long_text integer])
      expect_decoding(form, data: "1.foo bar that is very long 2.15",
                            answers: ["foo bar that is very long", 15])
    end

    it "text question in middle of message should work" do
      form = create_form(questions: %w[select_one text integer])
      expect_decoding(form, data: "1.a 2.foo bar 3.15", answers: ["Apple", "foo bar", 15])
    end

    it "long_text question in middle of message should work" do
      form = create_form(questions: %w[select_one long_text integer])
      expect_decoding(form,
        data: "1.a 2.foo bar that is very long 3.15",
        answers: ["Apple", "foo bar that is very long", 15])
    end

    it "text question at end of message should work" do
      form = create_form(questions: %w[select_one integer text])
      expect_decoding(form, data: "1.a 2.15 3.foo bar", answers: ["Apple", 15, "foo bar"])
    end

    it "long_text question at end of message should work" do
      form = create_form(questions: %w[select_one integer long_text])
      expect_decoding(form,
        data: "1.a 2.15 3.foo bar that is very long",
        answers: ["Apple", 15, "foo bar that is very long"])
    end

    it "text question with space after decimal should work" do
      form = create_form(questions: %w[select_one text integer])
      expect_decoding(form, data: "1.a 2. foo bar 3.15", answers: ["Apple", "foo bar", 15])
    end

    it "weird chunk should error" do
      form = create_form(questions: %w[select_one text integer])
      expect_decoding_fail(form,
        data: "1.a 2. foo bar 3.15 baz",
        error: "answer_not_integer", rank: 3, value: "15 baz")
    end

    it "date question should work" do
      form = create_form(questions: %w[integer date])
      expect_decoding(form, data: "1.4 2.20120229", answers: [4, Date.new(2012, 2, 29)])

      # check other formats
      expect_decoding(form, data: "1.4 2.2012/02/29", answers: [4, Date.new(2012, 2, 29)])
      expect_decoding(form, data: "1.4 2.2012.02.29", answers: [4, Date.new(2012, 2, 29)])
      expect_decoding(form, data: "1.4 2.2012.2.29", answers: [4, Date.new(2012, 2, 29)])
    end

    it "date question with invalid date should error" do
      form = create_form(questions: %w[integer date])
      expect_decoding_fail(form, data: "1.4 2.20120230", error: "answer_not_date", value: "20120230")
    end

    it "date question with too short date should error" do
      form = create_form(questions: %w[integer date])
      expect_decoding_fail(form, data: "1.4 2.2012230", error: "answer_not_date", value: "2012230")
    end

    it "date question with junk should error" do
      form = create_form(questions: %w[integer date])
      expect_decoding_fail(form, data: "1.4 2.foobarbaz",
                                 error: "answer_not_date", value: "foobarbaz")
    end

    it "time question should work" do
      utc = ActiveSupport::TimeZone.new("UTC")
      form = create_form(questions: %w[integer time])
      response = expect_decoding(form, data: "1.4 2.1230", answers: [4, utc.parse("2000-01-01 12:30")])

      # make sure time gets saved properly and zone doesn't mess up
      response.reload
      expect(response.answers.last.time_value.hour).to eq(12)

      # check other formats
      expect_decoding(form, data: "1.4 2.12:30", answers: [4, utc.parse("2000-01-01 12:30")])
      expect_decoding(form, data: "1.4 2.12:30pm", answers: [4, utc.parse("2000-01-01 12:30")])
      expect_decoding(form, data: "1.4 2.12:45PM", answers: [4, utc.parse("2000-01-01 12:45")])
      expect_decoding(form, data: "1.4 2.12.30pm", answers: [4, utc.parse("2000-01-01 12:30")])
      expect_decoding(form, data: "1.4 2.130", answers: [4, utc.parse("2000-01-01 1:30")])
      expect_decoding(form, data: "1.4 2.0130", answers: [4, utc.parse("2000-01-01 1:30")])
      expect_decoding(form, data: "1.4 2.1:30", answers: [4, utc.parse("2000-01-01 1:30")])
      expect_decoding(form, data: "1.4 2.1:30am", answers: [4, utc.parse("2000-01-01 1:30")])
      expect_decoding(form, data: "1.4 2.1:30pm", answers: [4, utc.parse("2000-01-01 13:30")])
    end

    it "invalid times should error" do
      form = create_form(questions: %w[integer time])
      ["12:300", "25:00", "00000", "12", "abc"].each do |str|
        expect_decoding_fail(form, data: "1.4 2.#{str}", error: "answer_not_time", value: str)
      end
    end

    it "datetime question should work" do
      form = create_form(questions: %w[integer datetime])

      Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

      response = expect_decoding(form,
        data: "1.4 2.20120229 1230",
        answers: [4, Time.zone.parse("2012-02-29 12:30")])

      # make sure time gets saved properly and zone doesn't mess up
      response.reload
      expect(response.answers.last.datetime_value.hour).to eq(12)

      # make sure timezone gets set properly (Saskatchewan is CST)
      expect(response.answers.last.datetime_value.zone.to_s).to eq("CST")

      # check other formats
      expect_decoding(form, data: "1.4 2.20120229 230",
                            answers: [4, Time.zone.parse("2012-02-29 2:30")])
      expect_decoding(form, data: "1.4 2.20120229 12:30pm",
                            answers: [4, Time.zone.parse("2012-02-29 12:30")])
      expect_decoding(form, data: "1.4 2.20120229 1:30",
                            answers: [4, Time.zone.parse("2012-02-29 1:30")])
      expect_decoding(form, data: "1.4 2.2012/02/29 12:30pm",
                            answers: [4, Time.zone.parse("2012-02-29 12:30")])
      expect_decoding(form, data: "1.4 2.2012-02-29 12:30pm",
                            answers: [4, Time.zone.parse("2012-02-29 12:30")])
      expect_decoding(form, data: "1.4 2.2012-11-1 12:30pm",
                            answers: [4, Time.zone.parse("2012-11-01 12:30")])
      expect_decoding(form, data: "1.4 2.201211011230",
                            answers: [4, Time.zone.parse("2012-11-01 12:30")])
      expect_decoding(form, data: "1.4 2.201211010230",
                            answers: [4, Time.zone.parse("2012-11-01 2:30")])
    end

    it "invalid datetimes should error" do
      form = create_form(questions: %w[integer datetime])
      ["2012121212300", "mar 1 2012 2:30", "201212", "891015 12pm", "2-2-2012 5pm"].each do |str|
        expect_decoding_fail(form, data: "1.4 2.#{str}", error: "answer_not_datetime", value: str)
      end
    end

    it "answers for questions in groups should work" do
      form = create_form(questions: ["integer", %w[text date], "date"])
      response = create_response(form, data: "1.3 2.coffee and bagels 3.20151225 4.20160101")

      expect_children(
        response.root_node,
        %w[Answer AnswerGroup Answer],
        form.c.map(&:id),
        [3, nil, Date.new(2016, 0o1, 0o1)]
      )
      expect_children(
        response.c[1],
        %w[Answer Answer],
        form.c[1].c.map(&:id),
        ["coffee and bagels", Date.new(2015, 12, 25)]
      )
    end

    it "answer too large should error" do
      question = create(:question, qtype_name: "integer", maximum: 20)
      form = create_form(questions: [question])
      expect_decoding_fail(form, data: "1. 21", error: "answer_too_large", value: "21")
    end

    it "answer strictly too large should fail" do
      question = create(:question, qtype_name: "integer", maximum: 20, maxstrictly: true)
      form = create_form(questions: [question])
      expect_decoding_fail(form, data: "1. 20", error: "answer_too_large_strict", value: "20")
    end

    it "answer too small should error" do
      question = create(:question, qtype_name: "integer", minimum: 20)
      form = create_form(questions: [question])
      expect_decoding_fail(form, data: "1. 19", error: "answer_too_small", value: "19")
    end

    it "answer strictly too small should fail" do
      question = create(:question, qtype_name: "integer", minimum: 20, minstrictly: true)
      form = create_form(questions: [question])
      expect_decoding_fail(form, data: "1. 20", error: "answer_too_small_strict", value: "20")
    end
  end

  describe "complex hierarchy construction" do
    it "builds response tree for nested groups with repeat" do
      # QingGroup (root)
      #   QingGroup
      #     Questioning
      #   Questioning
      #   Questioning (multilevel)
      #   QingGroup (repeating)
      #     Questioning
      #     Questioning
      #     QingGroup
      #       Questioning
      form = create_form(
        questions: [
          %w[integer],
          "integer",
          "multilevel_select_one_as_text_for_sms",
          {repeating: {items: ["integer", "integer", %w[integer]]}}
        ],
        default_option_names: true
      )

      # 1. AnswerGroup
      #   1. AnswerGroup
      #     1. Answer
      #   2. Answer
      #   3. AnswerSet
      #     1. Answer
      #     2. Answer
      #   4. AnswerGroupSet
      #     1. AnswerGroup
      #       1. Answer
      #       2. Answer
      #       3. AnswerGroup
      #         1. Answer
      response = create_response(form, data: "1.1 2.2 3.tulip 4.4 5.5 6.6")

      expect_children(
        response.root_node,
        %w[AnswerGroup Answer AnswerSet AnswerGroupSet],
        form.c.map(&:id),
        [nil, 2, nil, nil]
      )
      expect_children(
        response.c[0],
        %w[Answer],
        form.c[0].c.map(&:id),
        [1]
      )
      expect_children(
        response.c[2],
        %w[Answer Answer],
        [form.c[2].id] * 2,
        %w[Plant Tulip]
      )
      expect_children(
        response.c[3],
        %w[AnswerGroup],
        [form.c[3].id],
        [nil]
      )
      expect_children(
        response.c[3].c[0],
        %w[Answer Answer AnswerGroup],
        form.c[3].c.map(&:id),
        [4, 5, nil]
      )
      expect_children(
        response.c[3].c[0].c[2],
        %w[Answer],
        form.c[3].c[2].c.map(&:id),
        [6]
      )
    end
  end

  describe "duplicate checking" do
    it "duplicate sent within timeframe should error" do
      form = create_form(questions: %w[integer])
      expect_decoding(form, data: "1.4", answers: [4])
      Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW - 1.minute) do
        expect_decoding_fail(form, data: "1.4", error: "duplicate_submission")
      end
    end

    it "duplicate sent outside timeframe should not error" do
      form = create_form(questions: %w[integer])
      expect_decoding(form, data: "1.4", answers: [4])
      Timecop.travel(Sms::Decoder::DUPLICATE_WINDOW + 1.minute) do
        expect_decoding(form, data: "1.4", answers: [4])
      end
    end
  end

  private

  def create_form(options)
    option_names = options[:default_option_names] ? nil : %w[Apple Banana Cherry Durian] + ["Elder Berry"]
    authenticate_sms = options[:authenticate_sms] ? options[:authenticate_sms] : false
    form = create(:form,
      smsable: true,
      question_types: options[:questions],
      option_names: option_names,
      authenticate_sms: authenticate_sms)
    form.publish!
    form.reload
  end

  # You can provide the full message :body, or if :data is provided instead, `form.code` will be added
  # to the front of it to make the :body.
  def create_response(form, options)
    options[:user] ||= user
    options[:mission] = get_mission unless options.key?(:mission)
    options[:from] ||= options[:user].phone
    options[:body] ||= "#{form.code} #{options[:data]}"
    msg = Sms::Incoming.create(options.slice(:from, :body, :mission))
    decoder = Sms::Decoder.new(msg)
    decoder.decode
    decoder.finalize

    # Reload the response before testing to ensure everything is actually stored as we expect it.
    expect_response_basics(decoder.response.reload, form)
    decoder.response
  end

  def expect_response_basics(response, form)
    expect_root(response.root_node, form)
    expect(response.form_id).to eq(form.id)
  end

  # Tests that a decoding was successful. Returns the response in case further inspection is needed.
  # Works with single-level forms (no groups) only.
  def expect_decoding(form, options)
    response = create_response(form, options)

    # if we get this far and were expecting a failure, we didn't get one, so just return
    return if options[:expecting_fail]

    expect_children(
      response.root_node,
      ["Answer"] * options[:answers].size,
      form.c.map(&:id),
      options[:answers]
    )

    response
  end

  # tests that a decoding fails
  def expect_decoding_fail(form, options)
    error = nil
    begin
      expect_decoding(form, options.merge(expecting_fail: true))
    rescue Sms::DecodingError
      error = $ERROR_INFO
    end

    # ensure error of appropriate type was raised
    expect(error).not_to be_nil, "No error was raised"

    # ensure error params are correct
    expect(error.type).to eq(options[:error])
    expect(error.params[:rank]).to eq(options[:rank]) if options[:rank]
    expect(error.params[:value]).to eq(options[:value]) if options[:value]
  end
end
