# frozen_string_literal: true

require "rails_helper"

describe "OData root" do
  include_context "odata"

  let(:path) { mission_api_route }

  context "with no forms" do
    it "renders as expected" do
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata",
        value: []
      )
    end
  end

  context "with basic forms" do
    include_context "odata with basic forms"

    it "renders as expected" do
      names = ["Responses: #{form.name}", "Responses: #{form_with_no_responses.name}"]
      urls = %W[Responses-#{form.id} Responses-#{form_with_no_responses.id}]
      expect_json(
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata",
        value: [
          {name: names[0], kind: "EntitySet", url: urls[0]},
          {name: names[1], kind: "EntitySet", url: urls[1]}
        ]
      )
    end
  end
end
