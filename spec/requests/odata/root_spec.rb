# frozen_string_literal: true

require "rails_helper"

describe "OData root" do
  include_context "odata"

  let(:path) { mission_api_route }

  context "with no forms" do
    it "renders as expected" do
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{mission.compact_name}#{OData::BASE_PATH}/$metadata",
        value: []
      )
    end
  end

  context "with basic forms" do
    include_context "odata with basic forms"

    it "renders as expected" do
      forms = [form, form_with_no_responses, paused_form]
      values = forms.map do |form|
        {
          name: "Responses: #{form.name}",
          kind: "EntitySet",
          url: "Responses-#{form.id}"
        }
      end
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{mission.compact_name}#{OData::BASE_PATH}/$metadata",
        value: values
      )
    end
  end
end
