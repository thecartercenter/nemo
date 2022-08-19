# frozen_string_literal: true

require "rails_helper"
require "json"

describe DedupeJob do
  include_context "odk submissions"

  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let!(:question_types) { %w[text text text text] }
  let(:form1) { create(:form, :live, mission: mission, question_types: question_types) }
  let(:formver) { nil } # Don't override the version by default
  let(:fixture_name) { "simple_response" }
  let!(:xml) { prepare_odk_response_fixture(fixture_name, form1, values: xml_values, formver: formver) }
  let(:save_fixtures) { true }
  let(:r1_path) { "tmp/odk/responses/simple_response/simple_response.xml" }
  let(:r2_path) { "tmp/odk/responses/simple_response/simple_response2.xml" }
  let(:xml_values) { [1, 2, 3, 4] }

  after(:all) do
    FileUtils.rm_rf(DedupeJob::TMP_DUPE_BACKUPS_PATH)
    FileUtils.rm_rf(Rails.root.join("tmp/odk/responses/simple_response/"))
  end

  context "No dirty responses" do
    let!(:r1) { create(:response, dirty_dupe: false) }
    let!(:r2) { create(:response, dirty_dupe: false) }
    let!(:r3) { create(:response, dirty_dupe: false) }

    it "should not do anything" do
      described_class.perform_now
      expect(Response.all.count).to eq(3)
      expect(Response.find(r1.id)).to be_present
      expect(Response.find(r2.id)).to be_present
      expect(Response.find(r3.id)).to be_present
    end
  end

  context "Dirty responses but no odk xml attachments" do
    let!(:r1) { create(:response, dirty_dupe: true) }
    let!(:r2) { create(:response, dirty_dupe: true) }
    let!(:r3) { create(:response, dirty_dupe: true) }

    it "should change the dirty dupe flag but not delete" do
      expect(Response.dirty_dupe.count).to eq(3)
      described_class.perform_now
      expect(Response.dirty_dupe.count).to eq(0)
      expect(Response.find(r1.id)).to be_present
      expect(Response.find(r2.id)).to be_present
      expect(Response.find(r3.id)).to be_present
    end
  end

  context "Simple dedupe" do
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

    let(:optional_dupe) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end

    it "should remove a duplicate and create a copy" do
      expect(Response.dirty_dupe.count).to eq(3)
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      r2_json_path = "#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/#{r2.id}.json"
      r2_json = JSON.parse(File.read(r2_json_path))
      expected_json = {form_id: r2.form_id, odk_xml: r2.odk_xml.blob_id}.to_json
      expect(File.file?(r2_json_path)).to eq(true)
      expect(r2_json).to match_json(expected_json)
    end

    it "should reject a new duplicate even if an earlier one was previously destroyed" do
      optional_dupe # 3rd duplicate
      expect(Response.dirty_dupe.count).to eq(4)
      # Delete the FIRST duplicate but not the second
      ResponseDestroyer.new(scope: Response.where(id: r1.id)).destroy!
      expect(Response.all.count).to eq(3)
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
    end

    it "should work even when the queue piles up" do
      optional_dupe # 3rd duplicate
      expect(Response.all.count).to eq(4)
      # Seems like DelayedJob ensures these run one at a time serially, so this is pretty trivial.
      described_class.perform_later
      described_class.perform_later
      described_class.perform_later
      Delayed::Worker.new.work_off
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
    end
  end

  context "Duplicates with different missions" do
    let!(:mission_abc) { create(:mission) }
    let!(:form_abc) { create(:form, :live, mission: mission_abc, question_types: question_types) }
    let(:user_abc) { create(:user, role_name: "enumerator", mission: mission_abc) }

    let!(:mission_xyz) { create(:mission) }
    let!(:form_xyz) { create(:form, :live, mission: mission_xyz, question_types: question_types) }
    let(:user_xyz) { create(:user, role_name: "enumerator", mission: mission_xyz) }

    let!(:r1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form_abc,
        answer_values: xml_values,
        user_id: user_abc.id,
        dirty_dupe: false,
        mission: mission_abc
      )
    end

    let!(:r2) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form_xyz,
        answer_values: xml_values,
        user_id: user_xyz.id,
        dirty_dupe: false,
        mission: mission_xyz
      )
    end

    it "should not delete the responses" do
      expect(Response.count).to eq(2)
      described_class.perform_now
      expect(Response.count).to eq(2)
    end
  end

  context "Dedupe over time" do
    let!(:form2) { create(:form, :live, mission: mission, question_types: question_types) }
    let(:user2) { create(:user, role_name: "enumerator", mission: mission) }

    let!(:original_dupe1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id,
        dirty_dupe: false
      )
    end

    let!(:original_dupe2) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id,
        dirty_dupe: false
      )
    end

    it "should dedupe correctly", database_cleaner: :truncate do
      # Start with two existing dupes, but are clean
      described_class.perform_now
      expect(Response.all.count).to eq(2)

      # One new duplicate response that is dirty
      new_dupe1 = create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id,
        dirty_dupe: true
      )

      expect(Response.all.count).to eq(3)
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      expect(Response.where(id: new_dupe1.id)).to_not(be_present)

      prepare_unique_xml(form1, %w[cat dog bark meow], "simple_response2")

      # New original response (not a duplicate)
      new_orig1 =
        create(
          :response,
          :with_odk_attachment,
          xml_path: r2_path,
          form: form1,
          answer_values: %w[cat dog bark meow],
          user_id: user.id
        )

      described_class.perform_now

      expect(Response.all.count).to eq(3)
      expect(Response.find(new_orig1.id)).to be_present
      expect(Response.find(new_orig1.id).dirty_dupe).to be(false)

      # A new duplicate to the original ones
      new_dupe2 =
        create(
          :response,
          :with_odk_attachment,
          xml_path: r1_path,
          form: form1,
          answer_values: xml_values,
          user_id: user.id
        )
      expect(Response.all.count).to eq(4)
      described_class.perform_now
      expect(Response.all.count).to eq(3)
      expect(Response.where(id: new_dupe2.id)).to_not(be_present)
    end
  end

  context "More complex dedupe with different users" do
    let!(:form2) { create(:form, :live, mission: mission, question_types: question_types) }
    let!(:form3) { create(:form, :live, mission: mission, question_types: question_types) }
    let(:user2) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user3) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user4) { create(:user, role_name: "enumerator", mission: mission) }
    let(:user5) { create(:user, role_name: "enumerator", mission: mission) }
    let(:r2_path) { "tmp/odk/responses/simple_response/simple_response2.xml" }

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

    # duplicate
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

    let(:r3) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r2_path,
        form: form2,
        answer_values: xml_values,
        user_id: user2.id
      )
    end

    # duplicate
    let(:r4) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r2_path,
        form: form2,
        answer_values: xml_values,
        user_id: user2.id
      )
    end

    it "should remove two duplicates and create two copies" do
      prepare_unique_xml(form2, xml_values, "simple_response2")
      # Now that simple_response2.xml exists, create the other responses.
      r3
      r4

      expect(Response.dirty_dupe.count).to eq(4)
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(Response.find_by(shortcode: r2.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r1.shortcode)).to_not(eq(nil))
      expect(Response.find_by(shortcode: r4.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r3.shortcode)).to_not(eq(nil))
      # Check for backups
      r2_json_path = "#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/#{r2.id}.json"
      r4_json_path = "#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/#{r4.id}.json"

      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?(r2_json_path)).to eq(true)
      expect(File.file?(r4_json_path)).to eq(true)

      r2_json = JSON.parse(File.read(r2_json_path))
      r4_json = JSON.parse(File.read(r4_json_path))

      expected_json2 = {form_id: r2.form_id, odk_xml: r2.odk_xml.blob_id}.to_json
      expect(r2_json).to match_json(expected_json2)

      expected_json4 = {form_id: r4.form_id, odk_xml: r4.odk_xml.blob_id}.to_json
      expect(r4_json).to match_json(expected_json4)
    end
  end

  context "Responses with multiple media attachments" do
    let(:question_types) { %w[text image image image] }
    let(:question_types) { ["text", "image", ["image"], {repeating: {items: %w[image]}}] }
    let(:media_form) { create(:form, :live, mission: mission, question_types: question_types) }
    let(:media4) { create(:media_image) }
    let(:media5) { create(:media_image) }
    let(:media6) { create(:media_image) }

    let!(:r1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: media_form,
        answer_values: ["Cat", create(:media_image), [create(:media_image)], [create(:media_image)]],
        user_id: user.id
      )
    end

    let!(:r2) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: media_form,
        answer_values: ["Cat", media4, [media5], [media6]],
        user_id: user.id
      )
    end

    it "should remove dupe response and create appropriate backup file" do
      expect(Response.all.count).to eq(2)
      described_class.perform_now
      expect(Response.all.count).to eq(1)
      expect(Media::Object.all.count).to eq(3)
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      r2_json_path = "#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/#{r2.id}.json"

      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?(r2_json_path)).to eq(true)

      # Ensure the dupe media blobs still exist
      expect(ActiveStorage::Blob.find_by(id: media4.item.blob_id)).to be_present
      expect(ActiveStorage::Blob.find_by(id: media5.item.blob_id)).to be_present
      expect(ActiveStorage::Blob.find_by(id: media6.item.blob_id)).to be_present

      r2_json = JSON.parse(File.read(r2_json_path))
      expected_json2 = {
        form_id: r2.form_id,
        odk_xml: r2.odk_xml.blob_id,
        "qing#{media4.answer.questioning_id}": media4.item.blob_id,
        "qing#{media5.answer.questioning_id}": media5.item.blob_id,
        "qing#{media6.answer.questioning_id}": media6.item.blob_id
      }.to_json
      expect(r2_json).to match_json(expected_json2)
    end
  end

  private

  def prepare_unique_xml(form, values, filename)
    # prepare another unique xml file
    prepare_odk_response_fixture("simple_response", form, values: values, formver: "202211")
    r1_original_path = Rails.root.join("tmp/odk/responses/simple_response/simple_response.xml")
    r2_path = Rails.root.join("tmp/odk/responses/simple_response/#{filename}.xml")
    FileUtils.cp(r1_original_path, r2_path)
  end
end
