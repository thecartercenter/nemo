require "spec_helper"

describe "answers" do
  
  context "when getting for one" do

    before do
      api_user = FactoryGirl.create(:user)
      form_user = FactoryGirl.create(:user)
      mission = FactoryGirl.create(:mission, name: "mission1") 
      form = FactoryGirl.create(:form, mission: mission, name: "something")
      q1 = FactoryGirl.create(:question, mission: mission)

      form.questions << [q1]
      response_obj = FactoryGirl.create(:response, form: form, mission: mission, user: form_user)
      @a1 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q1.id, value: 10)

      response_obj = FactoryGirl.create(:response, form: form, mission: mission, user: form_user)
      @a2 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q1.id, value: 20)

      params = {form_id: form.id, question_id: q1.id}

      get api_v1_one_answer_path, params, {'HTTP_AUTHORIZATION' => "Token token=#{api_user.api_key}"}
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


  context "when getting for all" do

    before do
      api_user = FactoryGirl.create(:user)
      form_user = FactoryGirl.create(:user)
      mission = FactoryGirl.create(:mission, name: "mission1") 
      form = FactoryGirl.create(:form, mission: mission, name: "something")
      q1 = FactoryGirl.create(:question, mission: mission)
      q2 = FactoryGirl.create(:question, mission: mission)

      form.questions << [q1, q2]

      # response with 2 answers
      response_obj = FactoryGirl.create(:response, form: form, mission: mission, user: form_user)
      @a1 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q1.id, value: 10)
      @a2 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q2.id, value: 20)

      params = {form_id: form.id}

      get api_v1_all_answers_path, params, {'HTTP_AUTHORIZATION' => "Token token=#{api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of one responses" do
      expect(@answers_array.size).to eq 1
    end

    it "should contain two questions" do
      expect(@answers_array.first[:response][:answers].first[:question]).to eql @a1.question.name
      expect(@answers_array.first[:response][:answers].first[:question]).to eql @a2.question.name
    end

    it "should contain two answers" do
      expect(@answers_array.first[:response][:answers].first[:answer]).to eql @a1.casted_value
      expect(@answers_array.first[:response][:answers].last[:answer]).to eql @a2.casted_value
    end

  end

end
