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
end

shared_context "odata_with_forms" do
  before do
    # TODO: What to do about access_level: private on questions?
    @form = create(:form, question_types: %w[integer select_one text])
    create(:form, question_types: %w[text])

    Timecop.freeze(Time.now - 10.days) do
      create(:response, form: @form, answer_values: [1, "Dog", "Foo"])
    end
    Timecop.freeze(Time.now - 5.days) do
      create(:response, form: @form, answer_values: [2, "Cat", "Bar"])
    end
    create(:response, form: @form, answer_values: [3, "Mouse", "Baz"])
  end
end
