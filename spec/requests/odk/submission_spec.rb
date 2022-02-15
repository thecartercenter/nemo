# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
#
# NOTE: This spec file is the only one that uses the "odk submissions" context, which is deprecated.
# Future work on this file should switch it to using the newer method of building XML fixtures.
describe "odk submissions", :odk, type: :request do
  include_context "basic auth"
  include_context "odk submissions"

  let(:mission) { create(:mission) }
  let(:submission_mission) { mission }
  let(:submission_path) { "/m/#{submission_mission.compact_name}/submission" }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let(:form) { create(:form, :live, mission: mission, question_types: %w[integer]) }
  let(:formver) { nil } # Don't override the version by default
  let(:fixture_name) { "single_question" }
  let(:xml) { prepare_odk_response_fixture(fixture_name, form, values: [1], formver: formver) }
  let(:file) { Tempfile.new.tap { |f| f.write(xml) && f.rewind } }
  let(:upload) { Rack::Test::UploadedFile.new(file, "text/xml") }
  let(:request_params) { {xml_submission_file: upload, format: "xml"} }
  let(:nemo_response) { Response.first }
  let(:save_fixtures) { true }

  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
    ActionController::Base.allow_forgery_protection = false
  end

  context "get and head requests" do
    it "should return 204 and no content" do
      head(submission_path, params: {format: "xml"}, headers: auth_header)
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty

      get(submission_path, params: {format: "xml"}, headers: auth_header)
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end
  end

  context "normal submission" do
    it "should work and have mission set to current mission", database_cleaner: :truncate do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:created)
      expect(nemo_response.mission).to eq(mission)
      expect(nemo_response.device_id).to eq(nil)
    end

    it "should save device ID if present", database_cleaner: :truncate do
      post("#{submission_path}?deviceID=test", params: request_params, headers: auth_header)
      expect(response).to have_http_status(:created)
      expect(nemo_response.device_id).to eq("test")
    end
  end

  context "to mission user is not assigned to" do
    let(:submission_mission) { create(:mission) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with non-existent mission" do
    let(:submission_path) { "/m/foo/submission" }

    it "should raise error" do
      expect do
        post(submission_path, params: request_params, headers: auth_header)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "with draft form" do
    let(:formver) { "1999010100" }
    let(:form) { create(:form, :draft, question_types: %w[integer]) }

    it "should fail with 460" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:form_not_live)
    end
  end

  context "with paused form" do
    let(:form) { create(:form, :paused, question_types: %w[integer]) }

    it "should fail with 460" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:form_not_live)
    end
  end

  context "with old version of form" do
    let(:formver) { "1999010100" }

    it "should fail with upgrade_required" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:upgrade_required)
    end
  end

  context "without form version" do
    let(:fixture_name) { "no_version" }

    it "should fail with upgrade_required" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:upgrade_required)
    end
  end

  context "with locked mission" do
    let(:mission) { create(:mission, locked: true) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with inactive user" do
    let(:user) { create(:user, role_name: "enumerator", active: false) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with missing answer to required question" do
    let(:fixture_name) { "single_question" }
    let(:form) { create(:form, :live, mission: mission, question_types: %w[integer integer]) }

    before do
      form.c[1].update!(required: true)
    end

    it "should still accept response", database_cleaner: :truncate do
      post(submission_path, params: request_params, headers: auth_header)
      expect(response).to have_http_status(:created)
      expect(nemo_response.children.size).to eq(1)
    end
  end

  context "sequential duplicate submission" do
    let(:xml_values) { %w[A B C D] }
    let!(:form1) { create(:form, :live, mission: mission, question_types: question_types) }
    let!(:formver) { create(:form_version, code: "abc", number: "202211", form: form1) }
    let(:r1_path) { "tmp/odk/responses/simple_response/simple_response.xml" }
    let(:r1) do
      create(
        :response,
        :with_odk_attachment,
        xml_path: r1_path,
        form: form1,
        answer_values: xml_values,
        user_id: user.id
      )
    end
    let!(:question_types) { %w[text text text text] }

    it "should return created", database_cleaner: :truncate do
      prepare_odk_response_fixture("simple_response", form1, values: xml_values, formver: "202211")
      r1
      r1_original_path = Rails.root.join("tmp/odk/responses/simple_response/simple_response.xml")
      r2_path = Rails.root.join("tmp/odk/responses/simple_response/simple_response2.xml")
      FileUtils.cp(r1_original_path, r2_path)

      upload = Rack::Test::UploadedFile.new(r2_path, "text/xml")
      request_params = {xml_submission_file: upload, format: "xml"}
      expect do
        post(submission_path, params: request_params, headers: auth_header)
      end.to change { Response.all.count }.by(0)
      expect(response).to have_http_status(:created)
    end
  end
end
