# frozen_string_literal: true

require "rails_helper"

describe "odk media submissions", :odk, :reset_factory_sequences, type: :request do
  include_context "basic auth"
  include_context "odk submissions"

  let(:user) { create(:user, role_name: "enumerator") }
  let(:form) { create(:form, :live, question_types: %w[text image]) }
  # Complex form that intentionally takes longer to process, to reduce likelihood of flaky specs.
  let(:form_complex) { create(:form, :live, question_types: complex_question_types) }
  let(:complex_question_types) do
    [
      "integer",
      {repeating:
         {items: [
           "integer",
           {repeating: {items: %w[integer integer]}}
         ]}}
    ]
  end
  let(:mission) { form.mission }
  let(:tmp_path) { Rails.root.join("tmp/submission.xml") }
  let(:submission_path) { "/m/#{mission.compact_name}/submission" }

  context "with single part" do
    before do
      FileUtils.rm_rf(ResponsesController::TMP_UPLOADS_PATH)
    end

    it "should successfully process the submission and clean up", database_cleaner: :truncate do
      image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
      submission_file = prepare_and_upload_submission_file("single_part_media.xml")

      post submission_path, params: {xml_submission_file: submission_file, "the_swing.jpg" => image},
                            headers: auth_header
      expect(response).to have_http_status(:created)

      form_response = Response.last
      expect(form_response.form).to eq(form)
      expect(form_response.answers.count).to eq(2)
      expect(form_response.odk_xml.filename).to eq("submission.xml")
      expect(form_response.odk_xml.byte_size).to be > 0

      tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
      expect(FileUtils.rm(tmp_files)).to be_empty
    end

    it "should safely ignore simple duplicates", database_cleaner: :truncate do
      # Original
      submission_file = prepare_and_upload_submission_file("single_question.xml")
      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).to have_http_status(:created)

      # Duplicate
      submission_file = prepare_and_upload_submission_file("single_question.xml")
      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).to have_http_status(:created)

      expect(Response.count).to eq(1)

      form_response = Response.last
      expect(form_response.form).to eq(form)
      expect(form_response.answers.count).to eq(1)
      expect(form_response.odk_xml.byte_size).to be > 0

      tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
      expect(FileUtils.rm(tmp_files)).to be_empty
    end

    it "should safely ignore parallel duplicates", database_cleaner: :truncate do
      original = nil
      duplicate = nil

      original_file = prepare_and_upload_submission_file("nested_group_form_response.xml")
      duplicate_file = prepare_and_upload_submission_file("nested_group_form_response_duplicate.xml")

      thread1 = Thread.new do
        original = post(submission_path, params: {xml_submission_file: original_file},
                                         headers: auth_header)
      end

      thread2 = Thread.new do
        duplicate = post(submission_path, params: {xml_submission_file: duplicate_file},
                                          headers: auth_header)
      end

      thread1.join
      thread2.join

      expect(original).to be(Rack::Utils::SYMBOL_TO_STATUS_CODE[:created])
      expect(duplicate).to be(Rack::Utils::SYMBOL_TO_STATUS_CODE[:created])

      expect(Response.count).to eq(1)

      form_response = Response.last
      expect(form_response.form).to eq(form)
      expect(form_response.answers.count).to eq(2)
      expect(form_response.odk_xml.byte_size).to be > 0

      tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
      expect(FileUtils.rm(tmp_files)).to be_empty
    end

    context "without retries" do
      before do
        stub_const(ODK::ResponseSaver, "MAX_TRIES", 0)
      end

      it "should return error for parallel duplicates", database_cleaner: :truncate do
        original = nil
        duplicate = nil

        original_file = prepare_and_upload_submission_file("nested_group_form_response.xml")
        duplicate_file = prepare_and_upload_submission_file("nested_group_form_response_duplicate.xml")

        thread1 = Thread.new do
          original = post(submission_path, params: {xml_submission_file: original_file},
                                           headers: auth_header)
        end

        thread2 = Thread.new do
          duplicate = post(submission_path, params: {xml_submission_file: duplicate_file},
                                            headers: auth_header)
        end

        thread1.join
        thread2.join

        # order doesn't matter.
        expect([original, duplicate]).to contain_exactly(
          Rack::Utils::SYMBOL_TO_STATUS_CODE[:created],
          Rack::Utils::SYMBOL_TO_STATUS_CODE[:service_unavailable]
        )

        expect(Response.count).to eq(1)

        form_response = Response.last
        expect(form_response.form).to eq(form)
        expect(form_response.answers.count).to eq(2)
        expect(form_response.odk_xml.byte_size).to be > 0

        tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
        expect(FileUtils.rm(tmp_files).count).to eq(1)
      end
    end

    it "should save a temp file for failures" do
      submission_file = prepare_and_upload_submission_file("no_version.xml")

      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).not_to have_http_status(:created)

      tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
      expect(FileUtils.rm(tmp_files).count).to eq(1)
    end
  end

  context "with multiple parts" do
    let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

    it "should successfully process the submission", database_cleaner: :truncate do
      image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
      image2 = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
      submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
      submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")

      # Submit first part
      post submission_path,
        params: {
          xml_submission_file: submission_file,
          "the_swing.jpg" => image,
          "*isIncomplete*" => "yes"
        },
        headers: auth_header
      expect(response).to have_http_status(:created)
      expect(Response.count).to eq(1)
      expect(ActiveStorage::Attachment.count).to eq(2)

      # Submit second part
      post submission_path,
        params: {
          xml_submission_file: submission_file2,
          "another_swing.jpg" => image2
        },
        headers: auth_header

      expect(response).to have_http_status(:created)

      form_response = Response.first

      expect(form_response.form).to eq(form)
      expect(form_response.answers.count).to eq(3)
    end
  end

  def prepare_and_upload_submission_file(template)
    File.open(tmp_path, "w") do |f|
      f.write(prepare_odk_media_upload_fixture(template, form))
    end
    Rack::Test::UploadedFile.new(tmp_path, "text/xml")
  end

  def prepare_odk_media_upload_fixture(filename, form)
    prepare_fixture("odk/responses/#{filename}",
      form: [form.id],
      formver: [form.number],
      itemcode: ODK::DecoratorFactory.decorate_collection(form.preordered_items).map(&:odk_code))
  end
end
