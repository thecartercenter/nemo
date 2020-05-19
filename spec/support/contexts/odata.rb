# frozen_string_literal: true

# See also similar `contexts/api_context`.

shared_context "odata" do
  let(:api_route) { "/odata/v1" }
  let(:mission_api_route) { "/en/m/#{get_mission.compact_name}#{api_route}" }

  before do
    Timecop.freeze("2020-01-01T12:00Z")
  end

  after do
    Timecop.return
  end

  def expect_output(expected)
    get(path)
    expect(response).to have_http_status(:ok)
    # Don't worry about trailing newlines.
    expect(response.body.rstrip).to eq(expected.rstrip)
  end

  def expect_output_fixture(filename, forms: [])
    form_names = forms.map(&:name)
    form_q_names = forms.map(&:questionings).flatten.map(&:name)
    get(path)
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(prepare_fixture("odata/#{filename}", form: form_names,
                                                                     q_name: form_q_names))
  end
end

shared_context "odata_with_basic_forms" do
  let!(:form) { create(:form, :live, question_types: %w[integer select_one text]) }
  let!(:form_with_no_responses) { create(:form, :live, question_types: %w[text]) }
  let(:unpublished_form) { create(:form, question_types: %w[text]) }
  let(:other_mission) { create(:mission) }
  let(:other_form) { create(:form, :live, mission: other_mission, question_types: %w[text]) }

  before do
    Timecop.freeze(Time.now.utc - 10.days) do
      create(:response, form: form, answer_values: [1, "Dog", "Foo"])
    end
    Timecop.freeze(Time.now.utc - 5.days) do
      create(:response, form: form, answer_values: [2, "Cat", "Bar"])
    end
    create(:response, form: form, answer_values: [3, "Dog", "Baz"])
    create(:response, form: unpublished_form, answer_values: ["X"])
    create(:response, mission: other_mission, form: other_form, answer_values: ["X"])
  end
end

shared_context "odata_with_nested_groups" do
  let!(:form) { create(:form, :live, question_types: ["text", %w[text integer], ["text", %w[integer text]]]) }

  before do
    Timecop.freeze(Time.now.utc - 10.days) do
      create(:response, form: form, answer_values: [%w[A B], ["C", 10], ["D", [21, "E1"]]])
    end
    Timecop.freeze(Time.now.utc - 5.days) do
      create(:response, form: form, answer_values: [])
    end
  end
end
