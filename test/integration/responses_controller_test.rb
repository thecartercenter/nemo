require 'test_helper'

class ResponsesControllerTest < ActionDispatch::IntegrationTest

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

  private
    # builds a form and sends a submission to the given path
    def do_submission(path)
      f = FactoryGirl.create(:form, :question_types => %w(integer integer))
      build_odk_submission(f)
      uploaded = fixture_file_upload(Rails.root.join('test/fixtures/', ODK_XML_FILE), 'text/xml')
      post(path, {:xml_submission_file => uploaded, :format => 'xml'}, 'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password'))
    end

  	# build a sample xml submission for the given form (assumes all questions are integer questions)
  	# assigns answers in the sequence 5, 10, 15, ...
  	# stores the xml in a tmp file
  	def build_odk_submission(form)
  		File.open(Rails.root.join('test/fixtures/', ODK_XML_FILE).to_s, 'w') do |f|
	  		xml = "<?xml version='1.0' ?><data id=\"#{form.id}\">"
	  		form.questionings.each_with_index do |qing, i|
	  			xml += "<#{qing.question.odk_code}>#{(i+1)*5}</#{qing.question.odk_code}>"
	  		end
	  		xml += "</data>"
	  		f.write(xml)
	  	end
  	end

  	def submission_path(mission = nil)
      mission ||= get_mission
  		"/m/#{mission.compact_name}/submission"
  	end
end