require "spec_helper"
require "support/shared_context"

describe "responses" do

  context "when getting for one form" do

    include_context "mission_response_two_questions_with_answers"

    before do
      get api_v1_responses_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
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
      @form.update_attribute(:access_level, AccessLevel::PUBLIC)
      get api_v1_responses_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of one responses" do
      expect(@answers_array.size).to eq 1
    end

    it "should contain two questions" do
      expect(@answers_array.first[:answers].first[:question]).to eql @a1.question.name
      expect(@answers_array.first[:answers].first[:question]).to eql @a2.question.name
    end

    it "should contain two answers" do
      expect(@answers_array.first[:answers].first[:answer]).to eql @a1.casted_value
      expect(@answers_array.first[:answers].last[:answer]).to eql @a2.casted_value
    end

  end

  context "when getting for one public form and two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, AccessLevel::PUBLIC)
      get api_v1_responses_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of no answers" do
      expect(@answers_array.first[:answers]).to be_empty
    end

  end

  context "when getting for one public form and one public question, two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, AccessLevel::PUBLIC)
      @q = FactoryGirl.create(:question, mission: @mission, access_level: AccessLevel::PUBLIC)

      @form.questions << [@q]

      response_obj = FactoryGirl.create(:response, form: @form, mission: @mission, user: @form_user)
      @a = FactoryGirl.create(:answer, response: response_obj, questioning_id: @q.id, value: 40)
      
      get api_v1_responses_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should returen 0 answer if question was private" do
      expect(@answers_array.first[:answers]).to have(0).answers
    end

    it "should return array of 1 answers for public question" do
      expect(@answers_array.last[:answers]).to have(1).answer
      expect(@answers_array.last[:answers].first[:question]).to eql @q.name
    end

  end

  context "when getting for one private form and two private questions" do

    include_context "mission_response_two_private_questions_with_answers"

    before do
      @form.update_attribute(:access_level, AccessLevel::PRIVATE)
      get api_v1_responses_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of no response" do
      expect(@answers_array).to be_empty
    end

  end

end
