# frozen_string_literal: true

require "rails_helper"

describe "root json" do
  include_context "odata"

  let(:path) { mission_api_route }

  context "with no forms" do
    it "renders as expected" do
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata?mode=m",
        value: []
      }.to_json)
    end
  end

  context "with several forms" do
    include_context "odata_with_forms"

    it "renders as expected" do
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata?mode=m",
        value: [
          {name: "Responses: Sample Form 1", kind: "EntitySet", url: "Responses: Sample Form 1"},
          {name: "Responses: Sample Form 2", kind: "EntitySet", url: "Responses: Sample Form 2"}
        ]
      }.to_json)
    end
  end
end
