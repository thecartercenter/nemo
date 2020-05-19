# frozen_string_literal: true

require "rails_helper"

describe "$metadata" do
  include_context "odata"

  let(:path) { "#{mission_api_route}/$metadata" }

  context "with no forms" do
    it "renders as expected" do
      expect_output_fixture("empty_metadata.xml")
    end
  end

  context "with several basic forms" do
    include_context "odata_with_basic_forms"

    it "renders as expected" do
      expect_output_fixture("basic_metadata.xml", forms: [form, form_with_no_responses])
    end
  end

  context "with nested groups" do
    include_context "odata_with_nested_groups"

    it "renders as expected" do
      expect_output_fixture("nested_groups_metadata.xml", forms: [form])
    end
  end
end
