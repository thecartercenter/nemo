# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "zip"

describe Utils::XmlPackager do
  include_context "odk submissions"
  include ActionDispatch::TestProcess
  let(:save_fixtures) { true }
  let(:user) { create(:user, role_name: "coordinator") }
  let(:operation) { create(:operation, creator: user) }
  let(:response) { Response.new(form: form, mission: form.mission, user: user, source: "odk") }
  let(:formver) { "abc" } # Don't override the version by default
  let(:form) { create(:form, :live, questions: questions) }
  let(:xml) { prepare_odk_response_fixture(fixture_name, form, values: xml_values, formver: formver) }

  context "simple form" do
    let(:fixture_name) { "simple_response" }
    let(:questions) do
      [
        create(:question, qtype_name: "text", name: "firstname"),
        create(:question, qtype_name: "text", name: "lastname"),
        create(:question, qtype_name: "text", name: "dogname"),
        create(:question, qtype_name: "text", name: "catname")
      ]
    end
    let(:question_types) { %w[text text text text] }
    let(:xml_values) { %w[rhys dimond alfred honey] }

    before do
      response.odk_xml.attach(io: StringIO.new(xml), filename: "odk-response.xml", content_type: "xml")
      response.save
    end

    it "should calculate the size of the files" do
      ability = Ability.new(user: operation.creator, mission: operation.mission)
      packager = described_class.new(
        ability: ability, search: nil, selected: [], operation: operation
      )
      expect(packager.xml_size).to eq(674)
    end

    it "should replace the xml file with question names" do
      ability = Ability.new(user: operation.creator, mission: operation.mission)
      packager = described_class.new(
        ability: ability, search: nil, selected: [], operation: operation
      )
      human_readable_xml = packager.make_human_readable(response)
      expect(human_readable_xml).to include("<firstname>rhys</firstname>")
      expect(human_readable_xml).to include("<lastname>dimond</lastname>")
    end

    it "should zip one xml response" do
      ability = Ability.new(user: operation.creator, mission: operation.mission)
      packager = described_class.new(
        ability: ability, search: nil, selected: [], operation: operation
      )
      results = packager.download_and_zip_xml

      expect(results.basename.to_s).to match(/#{operation.mission.compact_name}-xml-responses.+.zip/)
      expect(File.exist?(results.to_s)).to be(true)

    end
  end
end
