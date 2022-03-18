# frozen_string_literal: true

require "rails_helper"

describe ODK::ResponseSaver do
  include_context "odk submissions"

  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let(:fixture_name) { "single_question" }
  let(:xml) { prepare_odk_response_fixture(fixture_name, form1, values: [1], formver: formver) }
  let(:file) { Tempfile.new.tap { |f| f.write(xml) && f.rewind } }
  let(:upload) { Rack::Test::UploadedFile.new(file, "text/xml") }
  let(:request_params) { {xml_submission_file: upload, format: "xml"} }
  let(:nemo_response) { Response.first }
  let(:save_fixtures) { true }

  context "race conditions" do
    let(:xml_values) { %w[A B C D] }
    let!(:form1) { create(:form, :live, mission: mission, question_types: question_types) }
    let!(:formver) { create(:form_version, code: "abc", number: "202211", form: form1) }
    let(:r1_path) { "tmp/odk/responses/simple_response/simple_response.xml" }
    let(:r1) do
      build(:response, :with_odk_attachment, xml_path: r1_path, form: form1,
                                             answer_values: xml_values, user_id: user.id)
    end
    let(:r2) do
      # Duplicate.
      build(:response, :with_odk_attachment, xml_path: r1_path, form: form1,
                                             answer_values: xml_values, user_id: user.id)
    end
    let!(:question_types) { %w[text text text text] }

    before do
      stub_const(ODK::ResponseSaver, "MAX_TRIES", 0)
      stub_const(ODK::ResponseSaver, "TEST_SLEEP_TIMER", 1)
    end

    it "should return a database serialization error", database_cleaner: :truncate do
      # make odk
      prepare_odk_response_fixture("simple_response", form1, values: xml_values, formver: "202211")
      e = nil

      begin
        thread1 = Thread.new do
          e = ODK::ResponseSaver.save_with_retries!(
            response: r1,
            submission_file: upload,
            user_id: user.id
          )
        end

        thread2 = Thread.new do
          # wait until the first thread is sleepin
          sleep(0.5)

          ODK::ResponseSaver.save_with_retries!(
            response: r2,
            submission_file: upload,
            user_id: user.id
          )
        end

        thread1.join
        thread2.join
      rescue ActiveRecord::SerializationFailure => e
        expect(Response.count).to eq(1)
        expect(ActiveStorage::Blob.all.count).to eq(1)
        expect(e.class).to eq(ActiveRecord::SerializationFailure)
      end
    end
  end
end
