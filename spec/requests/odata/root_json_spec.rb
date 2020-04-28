# frozen_string_literal: true

require "rails_helper"

describe "root json" do
  include_context "odata"

  let(:path) { mission_api_route }

  context "with no forms" do
    it "renders as expected" do
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata",
        value: []
      }.to_json)
    end
  end

  context "with several forms" do
    include_context "odata_with_forms"

    it "renders as expected" do
      entity_1_name = "Responses: #{form.name}"
      entity_2_name = "Responses: #{form_with_no_responses.name}"
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata",
        value: [
          {name: entity_1_name, kind: "EntitySet", url: entity_1_name},
          {name: entity_2_name, kind: "EntitySet", url: entity_2_name}
        ]
      }.to_json)
    end
  end
end
