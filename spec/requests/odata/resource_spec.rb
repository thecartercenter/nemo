# frozen_string_literal: true

require "rails_helper"

describe "OData resource" do
  include_context "odata"

  around do |example|
    # Use a consistent timezone so the output matches.
    in_timezone("Saskatchewan") { example.run }
  end

  context "with no forms" do
    let(:path) { "#{mission_api_route}/Responses-invalid" }

    it "renders as expected" do
      expect_output({
        "error": {
          "code": "",
          "message": "Resource not found for the segment 'Responses-invalid'."
        }
      }.to_json)
    end
  end

  context "with basic form" do
    include_context "odata with basic forms"

    let(:path) { "#{mission_api_route}/Responses-#{form.id}" }
    let(:first_response) { form.responses.first }

    it "renders as expected" do
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}" \
          "/odata/v1/$metadata#Responses: #{form.name}",
        value: [
          json_for(form, form.responses[0], "IntegerQ1": 3,
                                            "SelectOneQ2": "Dog",
                                            "TextQ3": "Baz"),
          json_for(form, form.responses[1], "IntegerQ1": 2,
                                            "SelectOneQ2": "Cat",
                                            "TextQ3": "Bar"),
          json_for(form, form.responses[2], "IntegerQ1": 1,
                                            "SelectOneQ2": "Dog",
                                            "TextQ3": "Foo")
        ]
      }.to_json)
    end
  end
end

def json_for(form, response, **answers)
  {
    "ResponseID": response.id,
    "ResponseShortcode": response.shortcode,
    "FormName": form.name,
    "ResponseSubmitterName": response.user.name,
    "ResponseSubmitDate": response.created_at.iso8601,
    "ResponseReviewed": false
  }.merge(answers)
end
