require 'test_helper'

# tests handling of odk collect requests
class OdkTest < ActionDispatch::IntegrationTest

  ODK_XML_FILE = 'odk_xml_file.xml'

  setup do
    @user = FactoryGirl.create(:user, :role_name => 'observer')
    @other_mission = FactoryGirl.create(:mission, :name => 'other mission')
  end

  test 'get and head requests should return 204 and no content' do
    head(submission_path, {:format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
    assert_response(204)
    assert_equal('', response.body)
    get(submission_path, {:format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
    assert_response(204)
    assert_equal('', response.body)
  end

  test 'odk submission should work and have mission set to current mission' do
    do_submission(submission_path)
    assert_response(201)
    assert_equal(5, assigns(:response).answers[0].value)
    assert_equal(10, assigns(:response).answers[1].value)
    assert_equal(get_mission, assigns(:response).mission)
  end

  test 'odk user submission to unassigned mission should fail' do
    do_submission(submission_path(@other_mission))
    assert_response(401)
  end

  test 'odk user submission to non-existent mission should fail' do
    do_submission('/m/foo/submission')
    assert_response(404)
  end

  test 'odk submission of integer value to select question should fail gracefully' do
    # create form with select one question
    form = FactoryGirl.create(:form, :question_types => %w(select_one))
    form.publish!
    form2 = FactoryGirl.create(:form, :name => 'other form', :question_types => %w(integer))
    form2.publish!

    # attempt submission to proper form
    xml = build_odk_submission(form2)
    do_submission(submission_path(get_mission), xml)

    # answer should look right
    resp = form2.reload.responses.last
    assert_equal('5', resp.answers.first.value)

    # attempt submission of value to wrong question
    xml = build_odk_submission(form2, :override_form_id => form.id)
    do_submission(submission_path(get_mission), xml)

    # answer should remain blank, integer value should not get stored
    resp = form.reload.responses.last
    assert_nil(resp.answers.first.value)
    assert_nil(resp.answers.first.option_id)
  end

  test 'submitting to old version of form should return error 426 upgrade required' do
    # create form build response xml based on it
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    f.publish!
    xml = build_odk_submission(f)
    old_version = f.current_version.sequence

    # change form and force an upgrade (verify upgrade happened)
    f.unpublish!
    f.questionings.first.required = true
    f.save!
    f.publish!
    assert_not_equal(old_version, f.reload.current_version.sequence)

    # try to submit old xml and check for error
    do_submission(submission_path(get_mission), xml)
    assert_response(426)
  end

  test 'submitting old xml without form version should return 426 also' do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    f.publish!

    # create old xml with no answers (don't need them) but valid form id
    xml = "<?xml version='1.0' ?><data id=\"#{f.id}\"></data>"

    do_submission(submission_path(get_mission), xml)
    assert_response(426)
  end

  private
    # builds a form and sends a submission to the given path
    def do_submission(path, xml = nil)
      f = FactoryGirl.create(:form, :question_types => %w(integer integer))
      f.publish!

      xml ||= build_odk_submission(f)

      # write xml to file
      require 'fileutils'
      FileUtils.mkpath('test/fixtures')
      fixture_file = Rails.root.join('test/fixtures/', ODK_XML_FILE)
      File.open(fixture_file.to_s, 'w') do |f|
        f.write(xml)
      end

      uploaded = fixture_file_upload(fixture_file, 'text/xml')
      post(path, {:xml_submission_file => uploaded, :format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
    end

    # build a sample xml submission for the given form (assumes all questions are integer questions)
    # assigns answers in the sequence 5, 10, 15, ...
    def build_odk_submission(form, options = {})
      # allow form id to be overridden for testing bad submissions
      form_id = options[:override_form_id] || form.id

      raise "form should have version" if form.current_version.nil?

      xml = "<?xml version='1.0' ?><data id=\"#{form_id}\" version=\"#{form.current_version.sequence}\">"
      form.questionings.each_with_index do |qing, i|
        xml += "<#{qing.question.odk_code}>#{(i+1)*5}</#{qing.question.odk_code}>"
      end
      xml += "</data>"
      xml
    end

    def submission_path(mission = nil)
      mission ||= get_mission
      "/m/#{mission.compact_name}/submission"
    end
end