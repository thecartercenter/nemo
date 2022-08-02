# frozen_string_literal: true

require "rails_helper"
require "json"

describe DedupeJob do
  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let!(:question_types) { %w[text text text text] }
  let(:form1) { create(:form, :live, mission: mission, question_types: question_types) }
  let(:fixture_name) { "single_question" }
  let(:save_fixtures) { true }
  let(:r1_path) { "tmp/odk/responses/simple_response/simple_response.xml" }
  let(:r2_path) { "tmp/odk/responses/simple_response/simple_response2.xml" }

  let(:xml_values) { [1, 2, 3, 4] }
  let(:xml_values2) { [5, 6, 7, 8] }

  after(:all) do
    FileUtils.rm_rf(DedupeJob::TMP_DUPE_BACKUPS_PATH)
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

  context "simple dedupe" do
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
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response.xml")).to eq(true)
    end
  end

  # context "Duplicates with different missions" do
  #   let!(:mission1) { create(:mission) }
  #   let!(:mission2) { create(:mission) }
  #   let!(:formabc) { create(:form, :live, mission: mission1, question_types: question_types) }
  #   let!(:formxyz) { create(:form, :live, mission: mission2, question_types: question_types) }
  #
  #   let!(:r1) do
  #     create(
  #       :response,
  #       :with_odk_attachment,
  #       xml_path: r1_path,
  #       form: formabc,
  #       answer_values: xml_values,
  #       user_id: user.id,
  #       dirty_dupe: false
  #     )
  #   end
  #
  #   let(:r2) do
  #     create(
  #       :response,
  #       :with_odk_attachment,
  #       xml_path: r1_path,
  #       form: formxyz,
  #       answer_values: xml_values,
  #       user_id: user.id
  #     )
  #   end
  #
  #   it "should not delete the responses" do
  #     expect(Response.count).to eq(1)
  #
  #     r2.created_at = DateTime.now + 20.minutes
  #     r2.save!
  #
  #     expect(Response.count).to eq(2)
  #     described_class.perform_now
  #     expect(Response.count).to eq(1)
  #   end
  # end

  context "dedupe over time" do
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

    it "should dedupe correctly" do
      # Start with two existing dupes, but are clean
      described_class.perform_now
      expect(Response.all.count).to eq(2)
      puts "first test"

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

      # New original response (note a duplicate)
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

  context "more complex dedupe with different users" do
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
      described_class.perform_now
      expect(Response.all.count).to eq(4)
      expect(Response.dirty_dupe.count).to eq(0)
      expect(Response.find_by(shortcode: r2.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r1.shortcode)).to_not(eq(nil))
      expect(Response.find_by(shortcode: r4.shortcode)).to eq(nil)
      expect(Response.find_by(shortcode: r3.shortcode)).to_not(eq(nil))
      # Check for backups
      expect(File.directory?(DedupeJob::TMP_DUPE_BACKUPS_PATH)).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response.xml")).to eq(true)
      expect(File.file?("#{DedupeJob::TMP_DUPE_BACKUPS_PATH}/simple_response2.xml")).to eq(true)
    end
  end

  private

  def print_responses
    Response.all.each do |r|
      puts "#{r.shortcode}:#{r.id}:#{r.created_at}:#{r.dirty_dupe}:#{r.blob_checksum}, \n"
    end
  end
end
