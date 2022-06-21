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
    it { expect_fixture("basic_metadata.xml", forms: [form, form_with_no_responses, paused_form]) }
  end

  context "with nested groups", :reset_factory_sequences do
    include_context "odata with nested groups"
    it { expect_fixture("nested_groups_metadata.xml", forms: [form]) }
  end

  context "with i18n", :reset_factory_sequences do
    include_context "odata with multilingual forms"
    it { expect_fixture("multilingual_metadata.xml", forms: [form]) }
  end
end
