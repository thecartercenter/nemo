# frozen_string_literal: true

# See also similar `contexts/api_context`.

shared_context "odata" do
  include_context "basic auth"

  let(:mission) { create(:mission) }
  let!(:user) { create(:user, mission: mission, role_name: :staffer) }
  let(:api_route) { OData::BASE_PATH }
  let(:mission_api_route) { "/en/m/#{mission.compact_name}#{api_route}" }

  before do
    Timecop.freeze("2020-01-01T12:00Z")
  end

  after do
    Timecop.return
  end

  def expect_json(expected)
    get(path, headers: auth_header)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to match_json(JSON.pretty_generate(expected))
  end

  def expect_fixture(filename, forms: [], substitutions: {})
    form_names = forms.map(&:name)
    form_q_codes = forms.map(&:questionings).flatten.map(&:code)
    get(path, headers: auth_header)
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(prepare_fixture("odata/#{filename}", form: form_names,
                                                                     q_code: form_q_codes,
                                                                     **substitutions))
  end
end

shared_context "odata with basic forms" do
  let!(:form) { create(:form, :live, mission: mission, question_types: %w[integer select_one text]) }
  let!(:form_with_no_responses) { create(:form, :live, mission: mission, question_types: %w[text]) }
  let(:unpublished_form) { create(:form, mission: mission, question_types: %w[text]) }
  let(:other_mission) { create(:mission) }
  let(:other_form) { create(:form, :live, mission: other_mission, question_types: %w[text]) }

  before do
    Timecop.freeze(Time.now.utc - 10.days) do
      create(:response, mission: mission, form: form, answer_values: [1, "Dog", "Foo"])
    end
    Timecop.freeze(Time.now.utc - 5.days) do
      create(:response, mission: mission, form: form, answer_values: [2, "Cat", "Bar"])
    end
    create(:response, mission: mission, form: form, answer_values: [3, "Dog", "Baz"])
    create(:response, mission: mission, form: unpublished_form, answer_values: ["X"])
    create(:response, mission: other_mission, form: other_form, answer_values: ["X"])
  end
end

shared_context "odata with nested groups" do
  let!(:form) { create(:form, :live, question_types: ["text", %w[text integer], ["text", %w[integer text]]]) }

  before do
    Timecop.freeze(Time.now.utc - 10.days) do
      create(:response, mission: mission, form: form, answer_values: [%w[A B], ["C", 10], ["D", [21, "E1"]]])
    end
    Timecop.freeze(Time.now.utc - 5.days) do
      create(:response, mission: mission, form: form, answer_values: [])
    end
  end
end
