# frozen_string_literal: true

require "rails_helper"
require "json"

describe DedupeJob do
  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let!(:question_types) { %w[text text text text] }
  let(:form1) { create(:form, :live, mission: mission, question_types: question_types) }
  let(:formver) { nil } # Don't override the version by default
  let(:fixture_name) { "single_question" }
  let(:nemo_response) { Response.first }
  let(:save_fixtures) { true }
  let(:r1_path) { "tmp/odk/responses/simple_response/simple_response.xml" }
  let(:r2_path) { "tmp/odk/responses/simple_response/simple_response2.xml" }

  let(:xml_values) { [1, 2, 3, 4] }

  before(:all) do
    Delayed::Worker.delay_jobs = false
  end

  after(:all) do
    FileUtils.rm_rf(DedupeJob::TMP_DUPE_BACKUPS_PATH)
  end

  context "No dirty responses" do
    let!(:r1) { create(:response, dirty_dupe: false) }
    let!(:r2) { create(:response, dirty_dupe: false) }
    let!(:r3) { create(:response, dirty_dupe: false) }

    it "should not do anything" do
      described_class.perform_later
      expect(Response.all.count).to eq(3)
    end
  end

  context "Dirty responses but no odk xml attachments" do
    let!(:r1) { create(:response, dirty_dupe: true) }
    let!(:r2) { create(:response, dirty_dupe: true) }
    let!(:r3) { create(:response, dirty_dupe: true) }

    it "should change the dirty dupe flag but not delete" do
      expect(Response.dirty_dupe.count).to eq(3)
      described_class.perform_later
      expect(Response.dirty_dupe.count).to eq(0)
    end
  end

  context "simple dedupe" do
    # create two identical responses (with same xml)
    let!(:r1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end

    let!(:r2) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end

    let!(:r3) do
      create(:response)
    end

    it "should remove a duplicate and create a copy" do
      expect(Response.dirty_dupe.count).to eq(3)
      described_class.perform_later
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response.xml")).to eq(true)
    end
  end

  context "more complex dedupe with different users" do
    # create two identical responses (with same xml)
    let!(:form2) { create(:form, :live, mission: mission, question_types: question_types) }
    let!(:form3) { create(:form, :live, mission: mission, question_types: question_types) }
    let(:user2) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user3) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user4) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user5) { create(:user, role_name: "enumerator", mission: mission) }

    let!(:r1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end

    let!(:r2) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end

    let!(:r3) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r2_path,
        form: form2,
        answer_values: xml_values,
        user_id: user2.id
      )
    end

    let!(:r4) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r2_path,
        form: form2,
        answer_values: xml_values,
        user_id: user2.id
      )
    end

    let!(:r5) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form2,
        answer_values: ["test", 2, "test", 4],
        user_id: user3.id
      )
    end

    let!(:r6) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form2,
        answer_values: [2, 2, 3, 4],
        user_id: user4.id
      )
    end

    it "should remove two duplicates and create two copies" do
      expect(Response.dirty_dupe.count).to eq(6)
      described_class.perform_later
      expect(Response.all.count).to eq(4)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(Response.find_by(shortcode: r1.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r2.shortcode)).to_not(eq(nil))
      expect(Response.find_by(shortcode: r3.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r4.shortcode)).to_not(eq(nil))
      # Check for backups
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response.xml")).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response2.xml")).to eq(true)
    end
  end
end
