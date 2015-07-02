require 'spec_helper'

# Using request spec b/c Authlogic won't work with controller spec
describe 'odk submissions', type: :request do

  ODK_XML_FILE = 'odk_xml_file.xml'

  context 'to regular mission' do

    before do
      @user = create(:user, :role_name => 'observer')
      @mission1 = get_mission
      @mission2 = create(:mission)
    end

    describe 'get and head requests' do
      it 'should return 204 and no content' do
        head(submission_path, {:format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
        expect(response.response_code).to eq 204
        expect(response.body).to be_empty

        get(submission_path, {:format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
        expect(response.response_code).to eq 204
        expect(response.body).to be_empty
      end
    end

    it 'should work and have mission set to current mission' do
      do_submission(submission_path)
      expect(response.response_code).to eq 201
      resp = Response.first
      expect(resp.answers[0].value).to eq '5'
      expect(resp.answers[1].value).to eq '10'
      expect(resp.mission).to eq get_mission
    end

    it 'should fail if user not assigned to mission' do
      do_submission(submission_path(@mission2))
      expect(response.response_code).to eq 403
    end

    it 'should fail for non-existent mission' do
      do_submission('/m/foo/submission')
      expect(response.response_code).to eq 404
    end

    it 'should return error 426 upgrade required if old version of form' do
      # Create form build response xml based on it
      f = create(:form, :question_types => %w(integer integer))
      f.publish!
      xml = build_odk_submission(f)
      old_version = f.current_version.sequence

      # Change form and force an upgrade (verify upgrade happened)
      f.unpublish!
      f.c[0].update_attributes!(required: true)
      f.reload.publish!
      expect(f.reload.current_version.sequence).not_to eq old_version

      # Try to submit old xml and check for error
      do_submission(submission_path(get_mission), xml)
      expect(response.response_code).to eq 426
    end

    it 'should return 426 if submitting xml without form version' do
      f = create(:form, :question_types => %w(integer integer))
      f.publish!

      # create old xml with no answers (don't need them) but valid form id
      xml = "<?xml version='1.0' ?><data id=\"#{f.id}\"></data>"

      do_submission(submission_path(get_mission), xml)
      expect(response.response_code).to eq 426
    end

    it 'should fail gracefully on question type mismatch' do
      # Create form with select one question
      form = create(:form, question_types: %w(select_one))
      form.publish!
      form2 = create(:form, question_types: %w(integer))
      form2.publish!

      # Attempt submission to proper form
      xml = build_odk_submission(form2)
      do_submission(submission_path(get_mission), xml)
      expect(response).to be_success

      # Answer should look right
      resp = form2.reload.responses.last
      expect(resp.answers.first.value).to eq '5'

      # Attempt submission of value to wrong question
      xml = build_odk_submission(form2, override_form_id: form.id)
      do_submission(submission_path(get_mission), xml)
      expect(response).to be_success

      # Answer should remain blank, integer value should not get stored
      resp = form.reload.responses.last
      expect(resp.answers.first.value).to be_nil
      expect(resp.answers.first.option_id).to be_nil
    end

    it 'should be marked incomplete iff there is an incomplete response to a required question' do
      form = create(:form, question_types: %w(integer), allow_incomplete: true)
      form.c[0].update_attributes!(required: true)
      form.reload.publish!

      [false, true].each do |no_answers|
        resp = do_submission(submission_path, build_odk_submission(form, no_answers: no_answers))
        expect(response.response_code).to eq 201
        expect(resp.incomplete).to be no_answers
      end
    end
  end

  context 'to locked mission' do
    before do
      @mission = create(:mission, locked: true)
      @user = create(:user, role_name: 'observer', mission: @mission)

    end

    it 'should fail' do
      resp = do_submission(submission_path(@mission), 'foo')
      expect(response.status).to eq 403
    end
  end

  # Builds a form (unless xml provided) and sends a submission to the given path.
  def do_submission(path, xml = nil)
    if xml.nil?
      form = create(:form, question_types: %w(integer integer))
      form.publish!
      xml = build_odk_submission(form)
    end

    # write xml to file
    require 'fileutils'
    FileUtils.mkpath('test/fixtures')
    fixture_file = Rails.root.join('test/fixtures/', ODK_XML_FILE)
    File.open(fixture_file.to_s, 'w') { |f| f.write(xml) }

    # Upload and do request.
    uploaded = fixture_file_upload(fixture_file, 'text/xml')
    post(path, {:xml_submission_file => uploaded, :format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
    assigns(:response)
  end

  # Build a sample xml submission for the given form (assumes all questions are integer questions)
  # Assigns answers in the sequence 5, 10, 15, ...
  def build_odk_submission(form, options = {})
    # allow form id to be overridden for testing bad submissions
    form_id = options[:override_form_id] || form.id

    raise "form should have version" if form.current_version.nil?

    ''.tap do |xml|
      xml << "<?xml version='1.0' ?><data id=\"#{form_id}\" version=\"#{form.current_version.sequence}\">"

      if options[:no_answers]
        if form.allow_incomplete?
          xml << "<#{OdkHelper::IR_QUESTION}>yes</#{OdkHelper::IR_QUESTION}>"
        end
      else
        form.questionings.each_with_index do |qing, i|
          xml << "<#{qing.question.odk_code}>#{(i+1)*5}</#{qing.question.odk_code}>"
        end
      end

      xml << "</data>"
    end
  end

  def submission_path(mission = nil)
    mission ||= get_mission
    "/m/#{mission.compact_name}/submission"
  end
end