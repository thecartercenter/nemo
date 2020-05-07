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
      names = ["Responses: #{form.name}", "Responses: #{form_with_no_responses.name}"]
      urls = %W[Responses-#{form.id} Responses-#{form_with_no_responses.id}]
      expect_output({
        "@odata.context": "http://www.example.com/en/m/#{get_mission.compact_name}/odata/v1/$metadata",
        value: [
          {name: names[0], kind: "EntitySet", url: urls[0]},
          {name: names[1], kind: "EntitySet", url: urls[1]}
        ]
      }.to_json)
    end
  end
end
