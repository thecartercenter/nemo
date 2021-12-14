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
  let(:xml) { prepare_odk_response_fixture(fixture_name, form, values: xml_values, formver: formver) }
  let(:ability) { Ability.new(user: operation.creator, mission: operation.mission) }
  let(:packager) { described_class.new(ability: ability, search: nil, selected: [], operation: operation) }

  context "simple form" do
    let(:form) { create(:form, :live, questions: questions) }
    let(:fixture_name) { "simple_response" }
    let(:questions) do
      [
        create(:question, qtype_name: "text", name: "firstname"),
        create(:question, qtype_name: "text", name: "lastname"),
        create(:question, qtype_name: "text", name: "dogname"),
        create(:question, qtype_name: "text", name: "catname")
      ]
    end
    let(:xml_values) { %w[rhys dimond alfred honey] }

    before do
      response.odk_xml.attach(io: StringIO.new(xml), filename: "odk-response.xml", content_type: "xml")
      response.save
    end

    it "should calculate the size of the files" do
      expect(packager.download_size).to eq(674)
    end

    it "should replace the xml file with question names" do
      q1 = form.c[0].code
      q2 = form.c[1].code
      human_readable_xml = packager.human_readable_xml(response)
      expect(human_readable_xml).to include("<#{q1} question='firstname'>rhys</#{q1}>")
      expect(human_readable_xml).to include("<#{q2} question='lastname'>dimond</#{q2}>")
    end

    it "should zip one xml response" do
      results = packager.download_and_zip_xml
      expect(results.basename.to_s).to match(/#{operation.mission.compact_name}-xml-responses.+.zip/)
      expect(File.exist?(results.to_s)).to be(true)
    end
  end

  context "response with repeat groups" do
    let(:fixture_name) { "repeat_group_form_response" }
    let(:question_types) { ["text", {repeating: {items: %w[text text]}}] }
    let(:xml_values) { %w[Hastings Wynn Dimond Rhys Dimond] }
    let(:form) { create(:form, :live, question_types: question_types) }

    before do
      names = %w[city firstname lastname]
      form.questions.each_with_index do |q, i|
        q.name = names[i]
        q.save
      end
      response.odk_xml.attach(io: StringIO.new(xml), filename: "odk-response.xml", content_type: "xml")
      response.save
    end

    it "should have the correct xml" do
      q1 = form.c[1].c[0].code
      human_readable_xml = packager.human_readable_xml(response)
      expect(human_readable_xml).to include("<#{q1} question='firstname'>Wynn</#{q1}>")
      expect(human_readable_xml).to include("<#{q1} question='firstname'>Rhys</#{q1}>")
    end
  end
end
