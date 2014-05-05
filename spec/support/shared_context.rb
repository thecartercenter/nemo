# docs https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-context
  
shared_context "api_user_and_mission" do
  
  before(:each) do
    @api_user = FactoryGirl.create(:user)
    @form_user = FactoryGirl.create(:user)
    @mission = FactoryGirl.create(:mission, name: "mission1") 
    @form = FactoryGirl.create(:form, mission: @mission, name: "something")  
  end

end

shared_context "mission_response_two_questions_with_answers" do
  
  include_context "api_user_and_mission"

  before(:each) do

    @q1 = FactoryGirl.create(:question, mission: @mission)
    @q2 = FactoryGirl.create(:question, mission: @mission)

    @form.questions << [@q1, @q2]

    # response with 2 answers
    response_obj = FactoryGirl.create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = FactoryGirl.create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)
    @a2 = FactoryGirl.create(:answer, response: response_obj, questioning_id: @q2.id, value: 20)
    @params = {form_id: @form.id}

  end

end

shared_context "mission_form_and_two_responses_answered" do
  
  include_context "api_user_and_mission"

  before(:each) do
    @q1 = FactoryGirl.create(:question, mission: @mission)

    @form.questions << [@q1]

    response_obj = FactoryGirl.create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = FactoryGirl.create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)

    response_obj = FactoryGirl.create(:response, form: @form, mission: @mission, user: @form_user)
    @a2 = FactoryGirl.create(:answer, response: response_obj, questioning_id: @q1.id, value: 20)

    @params = {form_id: @form.id, question_id: @q1.id}

  end

end
