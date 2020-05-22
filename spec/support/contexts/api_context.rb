# frozen_string_literal: true

# See also similar `contexts/odata`.

shared_context "api" do
  let(:mission) { create(:mission, name: "Mission 1") }
  let(:user) { create(:user, mission: mission) }
  let(:headers) { {"HTTP_AUTHORIZATION" => "Token token=#{user.api_key}"} }
  let(:bad_headers) { {"HTTP_AUTHORIZATION" => "Token token=xxx"} }
  let(:json) { JSON.parse(response.body) }
end

shared_context "api form with responses" do
  before do
    decoy = create(:form, mission: mission, access_level: "public", question_types: %w[integer])
    create(:response, form: decoy, answer_values: [1])

    @form = create(:form, mission: mission, access_level: "public",
                          question_types: %w[integer select_one text])
    @form.questions[2].update_attribute(:access_level, "private")

    Timecop.freeze(Time.now.utc - 10.days) do
      create(:response, form: @form, answer_values: [1, "Dog", "Bar"])
    end
    Timecop.freeze(Time.now.utc - 5.days) do
      create(:response, form: @form, answer_values: [2, "Cat", "Foo"])
    end
    create(:response, form: @form, answer_values: [3, "Dog", "Bar"])
  end
end
