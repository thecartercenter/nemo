# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
#
# NOTE: This spec file is the only one that uses the "odk submissions" context, which is deprecated.
# Future work on this file should switch it to using the newer method of building XML fixtures.
describe "odk submissions", :odk, type: :request do
  include_context "odk submissions"

  let(:mission) { create(:mission) }
  let(:submission_mission) { mission }
  let(:submission_path) { "/m/#{submission_mission.compact_name}/submission" }
  let(:user) { create(:user, role_name: "enumerator", mission: mission) }
  let(:auth_headers) { {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)} }
  let(:form) { create(:form, :live, :with_version, question_types: %w[integer]) }
  let(:formver) { nil } # Don't override the version by default
  let(:fixture_name) { "single_question" }
  let(:xml) { prepare_odk_response_fixture(fixture_name, form, values: [1], formver: formver) }
  let(:file) { Tempfile.new.tap { |f| f.write(xml) && f.rewind } }
  let(:upload) { fixture_file_upload(file, "text/xml") }
  let(:request_params) { {xml_submission_file: upload, format: "xml"} }
  let(:save_fixtures) { true }

  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
    ActionController::Base.allow_forgery_protection = false
  end

  context "get and head requests" do
    it "should return 204 and no content" do
      head(submission_path, params: {format: "xml"}, headers: auth_headers)
      expect(response).to have_http_status(204)
      expect(response.body).to be_empty

      get(submission_path, params: {format: "xml"}, headers: auth_headers)
      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
    end
  end

  context "normal submission" do
    let(:nemo_response) { Response.first }

    it "should work and have mission set to current mission" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(201)
      expect(nemo_response.mission).to eq(submission_mission)
    end
  end

  context "to mission user is not assigned to" do
    let(:submission_mission) { create(:mission) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(403)
    end
  end

  context "with non-existent mission" do
    let(:submission_path) { "/m/foo/submission" }

    it "should raise error" do
      expect do
        post(submission_path, params: request_params, headers: auth_headers)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "with draft form" do
    let(:form) { create(:form, :draft, question_types: %w[integer]) }

    it "should fail with 460" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(460)
    end
  end

  context "with paused form" do
    let(:form) { create(:form, :paused, question_types: %w[integer]) }

    it "should fail with 460" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(460)
    end
  end

  context "with old version of form" do
    let(:formver) { "junk" }

    it "should fail with 426" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(426)
    end
  end

  context "without form version" do
    let(:fixture_name) { "no_version" }

    it "should fail with 426" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(426)
    end
  end

  context "with locked mission" do
    let(:mission) { create(:mission, locked: true) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(403)
    end
  end

  context "with inactive user" do
    let(:user) { create(:user, role_name: "enumerator", active: false) }

    it "should fail" do
      post(submission_path, params: request_params, headers: auth_headers)
      expect(response).to have_http_status(401)
    end
  end
end
