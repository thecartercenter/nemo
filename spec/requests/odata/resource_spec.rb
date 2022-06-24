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
      expect_json(
        "error": {
          "code": "",
          "message": "Resource not found for the segment 'Responses-invalid'."
        }
      )
    end
  end

  context "with basic form", :reset_factory_sequences do
    include_context "odata with basic forms"

    let(:path) { "#{mission_api_route}/Responses-#{form.id}" }

    it "renders as expected" do
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{mission.compact_name}" \
          "#{OData::BASE_PATH}/$metadata#Responses: #{form.name}",
        value: [
          json_for(form, responses[2], "IntegerQ1": 3,
                                       "SelectOneQ2": "Dog",
                                       "TextQ3": "Baz"),
          json_for(form, responses[1], "IntegerQ1": 2,
                                       "SelectOneQ2": "Cat",
                                       "TextQ3": "Bar"),
          json_for(form, responses[0], "IntegerQ1": 1,
                                       "SelectOneQ2": "Dog",
                                       "TextQ3": "Foo")
        ]
      )
    end

    context "navigating to an Entry" do
      let(:path) { "#{mission_api_route}/Responses-#{form.id}(#{responses[0].id})" }

      it "renders as expected" do
        expect_json(
          json_for(form, responses[0], "IntegerQ1": 1,
                                       "SelectOneQ2": "Dog",
                                       "TextQ3": "Foo")
            .merge("@odata.context": "http://www.example.com/en/m/#{mission.compact_name}" \
              "#{OData::BASE_PATH}/$metadata#Responses: #{form.name}/$entity")
        )
      end
    end
  end

  context "with multilingual form", :reset_factory_sequences do
    include_context "odata with multilingual forms"

    let(:path) { "#{mission_api_route}/Responses-#{form.id}" }

    it "renders as expected" do
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{mission.compact_name}" \
          "#{OData::BASE_PATH}/$metadata#Responses: #{form.name}",
        value: [
          json_for(form, responses[0], "Groupe Un": {"SelectOneQ1": "Chat"})
        ]
      )
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
    "ResponseReviewed": false,
    "LastCached": Time.zone.now.iso8601
  }.merge(answers)
end
