require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "odk submissions", :odk, type: :request do
  include_context "odk submissions"

  before do
    allow_forgery_protection true
  end

  after do
    allow_forgery_protection false
  end

  context "to regular mission" do
    let!(:user) { create(:user, role_name: "enumerator") }
    let!(:mission1) { get_mission }
    let!(:mission2) { create(:mission) }

    describe "get and head requests" do
      it "should return 204 and no content" do
        head(submission_path, params: {format: "xml"}, headers: {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)})
        expect(response.response_code).to eq 204
        expect(response.body).to be_empty

        get(submission_path, params: {format: "xml"}, headers: {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)})
        expect(response.response_code).to eq 204
        expect(response.body).to be_empty
      end
    end

    it "should work and have mission set to current mission" do
      do_submission(submission_path)
      expect(response.response_code).to eq 201
      resp = Response.first
      expect(resp.answers.map(&:value)).to match_array ["5", "10"]
      expect(resp.mission).to eq get_mission
    end

    it "should fail if user not assigned to mission" do
      do_submission(submission_path(mission2))
      expect(response.response_code).to eq 403
    end

    it "should fail for non-existent mission" do
      expect { do_submission("/m/foo/submission") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return error 426 upgrade required if old version of form" do
      # Create form build response xml based on it
      f = create(:form, question_types: %w(integer integer))
      f.publish!
      xml = build_odk_submission(f)
      old_version = f.current_version.code

      # Change form and force an upgrade (verify upgrade happened)
      f.unpublish!
      f.c[0].update_attributes!(required: true)
      f.reload.publish!
      expect(f.reload.current_version.code).not_to eq old_version

      # Try to submit old xml and check for error
      do_submission(submission_path(get_mission), xml)
      expect(response.response_code).to eq 426
    end

    it "should return 426 if submitting xml without form version" do
      f = create(:form, question_types: %w(integer integer))
      f.publish!

      # create old xml with no answers (don't need them) but valid form id
      xml = "<?xml version='1.0' ?><data id=\"#{f.id}\"></data>"

      do_submission(submission_path(get_mission), xml)
      expect(response.response_code).to eq 426
    end

    it "should fail gracefully on question type mismatch", :investigate do
      # Create form with select one question
      form = create(:form, question_types: %w(select_one))
      form.publish!
      form2 = create(:form, question_types: %w(integer))
      form2.publish!

      # Attempt submission to proper form
      xml = build_odk_submission(form2, data: {form2.questionings[0] => "5"})
      do_submission(submission_path(get_mission), xml)
      expect(response).to be_success

      # Answer should look right
      resp = form2.reload.responses.last
      expect(resp.answers.first.value).to eq "5"

      # Attempt submission of value to wrong question
      xml = build_odk_submission(form)
      do_submission(submission_path(get_mission), xml)
      expect(response).to be_success

      # Answer should remain blank, integer value should not get stored
      resp = form.reload.responses.last
      expect(resp.answers.first.value).to be_nil
      expect(resp.answers.first.option_id).to be_nil
    end

    it "should be marked incomplete iff there is an incomplete response to a required question" do
      form = create(:form, question_types: %w(integer), allow_incomplete: true)
      form.c[0].update_attributes!(required: true)
      form.reload.publish!

      [false, true].each do |no_data|
        resp = do_submission(submission_path, build_odk_submission(form, no_data: no_data))
        expect(response.response_code).to eq 201
        expect(resp.incomplete).to be no_data
      end
    end
  end

  context "to locked mission" do
    let(:mission) { create(:mission, locked: true) }
    let(:user) { create(:user, role_name: "enumerator", mission: mission) }

    it "should fail" do
      resp = do_submission(submission_path(mission), "foo")
      expect(response.status).to eq 403
    end
  end

  context "inactive user" do
    let(:user) { create(:user, role_name: "enumerator", active: false) }
    let(:mission1) { get_mission }
    let(:mission2) { create(:mission) }

    it "should fail" do
      do_submission(submission_path)
      expect(response.response_code).to eq 401
    end
  end
end
