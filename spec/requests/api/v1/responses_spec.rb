require "spec_helper"
require "support/shared_context"

describe "responses" do
  context "when getting for one form" do

    include_context "mission_response_two_questions_with_answers"

    before do
      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    it "should return array of one responses" do
      expect(@answers_array.size).to eq 1
    end

    it "should contain two questions" do
      expect(@answers_array.first[:answers].first[:question]).to eql @a1.question.name
      expect(@answers_array.first[:answers].last[:question]).to eql @a2.question.name
    end

    it "should contain two answers" do
      expect(@answers_array.first[:answers].first[:answer]).to eql @a1.casted_value
      expect(@answers_array.first[:answers].last[:answer]).to eql @a2.casted_value
    end

  end

  context "when getting for one public form and public questions" do

    include_context "mission_response_two_questions_with_answers"

    before do
      @form.update_attribute(:access_level, 'public')
      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    it "should return array of one responses" do
      expect(@answers_array.size).to eq 1
    end

    it "should contain two questions" do
      expect(@answers_array.first[:answers].first[:question]).to eql @a1.question.name
      expect(@answers_array.first[:answers].last[:question]).to eql @a2.question.name
    end

    it "should contain two answers" do
      expect(@answers_array.first[:answers].first[:answer]).to eql @a1.casted_value
      expect(@answers_array.first[:answers].last[:answer]).to eql @a2.casted_value
    end

  end

  context "when getting for one public form and two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, 'public')
      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    it "should return array of no answers" do
      expect(@answers_array.first[:answers]).to be_empty
    end

  end

  context "when getting for one public form and one public question, two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, 'public')
      @question = FactoryGirl.create(:question, mission: @mission, add_to_form: @form)

      response_obj = FactoryGirl.create(:response, form: @form, mission: @mission, user: @form_user, answer_values: [10,20,40])
      @answer = response_obj.answers.first

      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    # it "should return 0 answer if question was private" do
    #   expect(@answers_array.first[:answers]).to be_empty
    # end

    it "should return array of 1 answers for public question" do
      expect(@answers_array.last[:answers].size).to eq 1
      expect(@answers_array.last[:answers].first[:question]).to eql @question.name
    end

  end

  context "when getting for one private form and two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, 'private')
      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    it "should return array of no response" do
      expect(@answers_array).to be_empty
    end

  end

  context "when getting a protected form with one public and private question" do

    include_context "mission_protected_form_one_public_private_question"

    before do
      allow(API::V1::AnswerFinder).to receive(:form_with_permissions) { @form }
      do_api_request(:responses, :params => @params)
      @answers_array = parse_json(response.body)
    end

    it "should have 1 answer" do
      expect(@answers_array.size).to eq 1
    end

  end

  context "filtering" do

    include_context "mission_form_and_two_responses_answered"

    context "should find answers after a date" do
      before do
        @response2.update_attribute(:created_at, 2.days.from_now)
        @params[:created_after] = (@response1.created_at + 1.day).to_s

        do_api_request(:responses, :params => @params)
        @answers_array = parse_json(response.body)
      end

      it "should find 1 response" do
        expect(@answers_array.size).to eq 1
      end
    end

    context "should find answers before a date" do
      before do
        @response1.update_attribute(:created_at, 1.days.from_now)
        @params[:created_before] = @response1.created_at.to_s
        do_api_request(:answers, :params => @params)
        @answers_array = parse_json(response.body)
      end

      it "should find 1 answer" do
        expect(@answers_array.size).to eq 1
      end
    end

  end
end
