# docs https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-context

shared_context "api_user_and_mission" do

  before(:each) do
    @mission = create(:mission)
    @api_user = create(:user)
    @form_user = create(:user)
    @form = create(:form, mission: @mission, name: "something", access_level: 'public')
  end

end

shared_context "mission_response_two_questions_with_answers" do

  include_context "api_user_and_mission"

  before(:each) do

    @q1 = create(:question, mission: @mission)
    @q2 = create(:question, mission: @mission)

    @form.questions << [@q1, @q2]

    # response with 2 answers
    response_obj = create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)
    @a2 = create(:answer, response: response_obj, questioning_id: @q2.id, value: 20)
    @params = {form_id: @form.id}

  end

end

shared_context "mission_response_two_private_questions_with_answers" do

  include_context "api_user_and_mission"

  before(:each) do

    @q1 = create(:question, mission: @mission, access_level: 'private')
    @q2 = create(:question, mission: @mission, access_level: 'private')

    @form.questions << [@q1, @q2]

    # response with 2 answers
    response_obj = create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)
    @a2 = create(:answer, response: response_obj, questioning_id: @q2.id, value: 20)
    @params = {form_id: @form.id}

  end

end

shared_context "mission_form_and_two_responses_answered" do

  include_context "api_user_and_mission"

  before(:each) do
    @q1 = create(:question, mission: @mission)

    @form.questions << [@q1]

    @response1 = create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = create(:answer, response: @response1, questioning_id: @q1.id, value: 10)

    @response2 = create(:response, form: @form, mission: @mission, user: @form_user)
    @a2 = create(:answer, response: @response2, questioning_id: @q1.id, value: 20)

    @params = {form_id: @form.id, question_id: @q1.id}

  end

end

shared_context "mission_form_one_private_question" do

  include_context "api_user_and_mission"

  before(:each) do
    @q1 = create(:question, mission: @mission, access_level: 'private')

    @form.questions << [@q1]

    response_obj = create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)

    response_obj = create(:response, form: @form, mission: @mission, user: @form_user)
    @a2 = create(:answer, response: response_obj, questioning_id: @q1.id, value: 20)

    @params = {form_id: @form.id, question_id: @q1.id}

  end

end

shared_context "mission_protected_form_one_public_private_question" do

  include_context "api_user_and_mission"

  before(:each) do
    @api_user = create(:user)
    @form.update_attribute(:access_level, 'protected')
    @form.whitelist_users.create(user_id: @api_user.id)

    @q1 = create(:question, mission: @mission)
    @q2 = create(:question, mission: @mission, access_level: 'private')

    @form.questions << [@q1, @q2]

    response_obj = create(:response, form: @form, mission: @mission, user: @form_user)
    @a1 = create(:answer, response: response_obj, questioning_id: @q1.id, value: 10)
    @a2 = create(:answer, response: response_obj, questioning_id: @q2.id, value: 20)

    @params = {form_id: @form.id}

  end

end
