require "spec_helper"
require "support/shared_context"

describe "answers" do
  
  context "when getting for one question" do
    
    include_context "mission_form_and_two_responses_answered"

    before do
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 2" do
      expect(@answers_array.size).to eq 2
    end

    it "should contain an answer from each response" do
      expect(@answers_array.first.has_value?(@a1.value)).to be_true
      expect(@answers_array.last.has_value?(@a2.value)).to be_true
    end

  end

  context "when getting for one public form with one private questions" do
    
    include_context "mission_form_one_private_question"

    before do
      @form.update_attribute(:access_level, AccessLevel::PUBLIC)
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 0" do
      expect(@answers_array.size).to eq 0
    end

  end

  context "when getting for one private form with one private questions" do
    
    include_context "mission_form_one_private_question"

    before do
      @form.update_attribute(:access_level, AccessLevel::PRIVATE)
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 0" do
      expect(@answers_array.size).to eq 0 
    end

  end

  context "filtering" do

    include_context "mission_form_and_two_responses_answered"

    context "should find answers after a date" do 
      before do
        @response2.update_attribute(:created_at, 2.days.from_now)
        @params[:created_after] = (@response1.created_at + 1.day).to_s 

        get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
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
        get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
        @answers_array = parse_json(response.body)
      end

      it "should find 1 answer" do
        expect(@answers_array.size).to eq 1
      end
    end

  end

end
