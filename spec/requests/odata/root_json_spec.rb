# frozen_string_literal: true

require "rails_helper"

describe "root json" do
  include_context "odata"

  let(:path) { root }

  context "with no forms" do
    it "renders as expected" do
      expect_output({
        "@odata.context" => "http://www.example.com/odata/v1?locale=en/$metadata?locale=en",
        value: []
      }.to_json)
    end
  end

  context "with several forms" do
    include_context "odata_with_forms"

    it "renders as expected" do
      expect_output({
        "@odata.context" => "http://www.example.com/odata/v1?locale=en/$metadata?locale=en",
        value: [
          # TODO: This should eventually include both forms.
          {name: "Responses: Sample Form 1", kind: "EntitySet", url: "Responses: Sample Form 1"},
        ]
      }.to_json)
    end
  end
end
