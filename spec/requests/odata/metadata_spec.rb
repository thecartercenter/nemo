# frozen_string_literal: true

require "rails_helper"

describe "OData $metadata" do
  include_context "odata"

  let(:path) { "#{mission_api_route}/$metadata" }

  context "with no forms" do
    it { expect_fixture("empty_metadata.xml") }
  end

  context "with several basic forms" do
    include_context "odata with basic forms"
    it { expect_fixture("basic_metadata.xml", forms: [form, form_with_no_responses]) }
  end

  context "with nested groups" do
    include_context "odata with nested groups"
    it do
      substitutions = {group_name: ["Group 3 (1)", "Group 1 (1)", "Group 2 (2)"]}
      expect_fixture("nested_groups_metadata.xml", forms: [form], substitutions: substitutions)
    end
  end
end
