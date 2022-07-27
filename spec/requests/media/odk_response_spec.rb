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

    it "should not be flagged as duplicate when response is not there" do
      # Original
      submission_file = prepare_and_upload_submission_file("single_question.xml")
      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).to have_http_status(:created)

      Response.first.destroy!

      # Submit same xml again
      submission_file = prepare_and_upload_submission_file("single_question.xml")
      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).to have_http_status(:created)

      expect(Response.count).to eq(1)
    end

    it "should save a temp file for failures" do
      submission_file = prepare_and_upload_submission_file("no_version.xml")

      post submission_path, params: {xml_submission_file: submission_file}, headers: auth_header
      expect(response).not_to have_http_status(:created)

      tmp_files = Dir.glob(ResponsesController::TMP_UPLOADS_PATH.join("*.xml"))
      expect(FileUtils.rm(tmp_files).count).to eq(1)
    end
  end

  context "multi-part submissions" do
    context "with multiple parts" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

      it "should successfully process the submission", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        image2 = Rack::Test::UploadedFile.new(image_fixture("sassafras.jpg"), "image/jpeg")
        submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")

        post_submission(submission_file, "the_swing.jpg", image, incomplete: true)
        expect_submission

        post_submission(submission_file2, "sassafras.jpg", image2, incomplete: false)
        expect_submission(num_attachments: 3)
        expect_answers
      end
    end

    context "with multiple parts, duplicate submissions for first part" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

      it "should ignore the second submission", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        image2 = Rack::Test::UploadedFile.new(image_fixture("sassafras.jpg"), "image/jpeg")
        submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file3 = prepare_and_upload_submission_file("multiple_part_media.xml")

        post_submission(submission_file, "the_swing.jpg", image, incomplete: true)
        expect_submission

        post_submission(submission_file2, "the_swing.jpg", image, incomplete: true)
        expect_submission

        post_submission(submission_file3, "sassafras.jpg", image2, incomplete: false)
        expect_submission(num_attachments: 3)

        expect_answers
      end
    end

    context "with multiple parts, duplicate submissions for second part" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

      it "should ignore the third submission as it is a duplicate", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        image2 = Rack::Test::UploadedFile.new(image_fixture("sassafras.jpg"), "image/jpeg")
        submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file3 = prepare_and_upload_submission_file("multiple_part_media.xml")

        post_submission(submission_file, "the_swing.jpg", image, incomplete: true)
        expect_submission

        post_submission(submission_file2, "sassafras.jpg", image2, incomplete: false)
        expect_submission(num_attachments: 3)

        post_submission(submission_file3, "sassafras.jpg", image2, incomplete: false)
        expect_submission(num_attachments: 3)

        expect_answers
      end
    end

    context "with multiple parts, duplicate first submission at the end" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

      it "should successfully process the submission", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        image2 = Rack::Test::UploadedFile.new(image_fixture("sassafras.jpg"), "image/jpeg")
        submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file3 = prepare_and_upload_submission_file("multiple_part_media.xml")

        post_submission(submission_file, "the_swing.jpg", image, incomplete: true)
        expect_submission

        post_submission(submission_file2, "sassafras.jpg", image2, incomplete: false)
        expect_submission(num_attachments: 3)

        post_submission(submission_file3, "the_swing.jpg", image, incomplete: true)
        expect_submission(num_attachments: 3)

        expect_answers
      end
    end

    context "with multiple parts, duplicate xml/image and no response" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch]) }

      it "should successfully process the submission", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        submission_file = prepare_and_upload_submission_file("multiple_part_media.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media.xml")

        post_submission(submission_file, "the_swing.jpg", image, incomplete: true)
        expect_submission

        Response.first.destroy!
        # Still keep the blobs
        expect(ActiveStorage::Blob.count).to eq(2)

        post_submission(submission_file2, "the_swing.jpg", image, incomplete: true)
        expect_submission
        expect(ActiveStorage::Blob.count).to eq(4)
      end
    end

    context "multiple media attachments in multiple responses" do
      let(:form) { create(:form, :live, question_types: %w[text image sketch image]) }

      it "should successfully process the submission", database_cleaner: :truncate do
        image = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        image2 = Rack::Test::UploadedFile.new(image_fixture("sassafras.jpg"), "image/jpeg")
        image3 = Rack::Test::UploadedFile.new(image_fixture("sassafras2.jpg"), "image/jpeg")

        submission_file = prepare_and_upload_submission_file("multiple_part_media2.xml")
        submission_file2 = prepare_and_upload_submission_file("multiple_part_media2.xml")

        submission_params = {
          xml_submission_file: submission_file,
          "the_swing.jpg" => image,
          "sassafras.jpg" => image2,
          "*isIncomplete*" => "yes"
        }

        post(submission_path, params: submission_params, headers: auth_header)
        expect(response).to have_http_status(:created)
        expect(Response.all.count).to eq(1)
        expect(::Media::Object.all.count).to eq(2)

        submission_params = {
          xml_submission_file: submission_file2,
          "the_swing.jpg" => image,
          "sassafras2.jpg" => image3,
          "*isIncomplete*" => "no"
        }

        post(submission_path, params: submission_params, headers: auth_header)
        expect(response).to have_http_status(:created)
        expect(Response.all.count).to eq(1)
        expect(::Media::Object.all.count).to eq(3)
      end
    end
  end

  def expect_submission(status: :created, num_response: 1, num_attachments: 2)
    expect(response).to have_http_status(status)
    expect(Response.count).to eq(num_response)
    expect(ActiveStorage::Attachment.count).to eq(num_attachments)
  end

  def expect_answers
    form_response = Response.first
    expect(form_response.form).to eq(form)
    expect(form_response.answers.count).to eq(3)
  end
end
