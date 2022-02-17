# frozen_string_literal: true

require "rails_helper"

describe ODK::ResponseSaver do
  include_context "odk submissions"

  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let(:fixture_name) { "single_question" }
  let(:xml) { prepare_odk_response_fixture(fixture_name, form, values: [1], formver: formver) }
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
      build(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end
    let!(:question_types) { %w[text text text text] }

    before do
      stub_const(ODK::ResponseSaver, "MAX_TRIES", 0)
      stub_const(ODK::ResponseSaver, "SLEEP_TIMER", 5)
    end

    it "should return a database serialization error", database_cleaner: :truncate do
      # make odk
      prepare_odk_response_fixture("simple_response", form1, values: xml_values, formver: "202211")
      r1_path = Rails.root.join("tmp/odk/responses/simple_response/simple_response.xml")
      upload = Rack::Test::UploadedFile.new(r1_path, "text/xml")
      checksum = ODK::ResponseParser.compute_checksum_in_chunks(upload)
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
          sleep(3)
          insert_response_via_second_db_connection(checksum)
        end

        thread1.join
        thread2.join
      rescue ActiveRecord::SerializationFailure => e
        expect(ActiveStorage::Blob.all.count).to eq(1)
        expect(e.class).to eq(ActiveRecord::SerializationFailure)
      end
    end
  end

  def insert_response_via_second_db_connection(checksum)
    db = ActiveRecord::Base.connection_pool.checkout
    db.execute("start transaction isolation level serializable;")
    db.execute("select * from active_storage_blobs WHERE checksum='#{checksum}';")
    db.execute("INSERT INTO active_storage_blobs
      (checksum, byte_size, content_type, filename, key, service_name, created_at)
      VALUES ('#{checksum}', 10000, 'application/xml', 'simple_response.xml', 'abc123', 'test', NOW());")
    db.execute("COMMIT;")
    ActiveRecord::Base.connection_pool.checkin(db)
  end
end
