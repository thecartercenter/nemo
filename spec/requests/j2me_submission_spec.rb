require 'spec_helper'
require 'fileutils'

describe 'j2me submissions', :type => :request do

  context 'for a valid user and mission' do
    before do
      @mission = FactoryGirl.create(:mission)
      @user = FactoryGirl.create(:user, :role_name => :observer)
      @submission_url = "/m/#{@mission.compact_name}/submission"
      @form = FactoryGirl.create(:form, :mission => @mission, :question_types => %w(integer))
      @form.publish!
      @question = @form.questions.first
      # Include the commcare tag we use to distinguish j2me requests
      submit_xml_response(:user => @user, :xml => "<#{@question.odk_code}>42</#{@question.odk_code}>
        <n1:appVersion xmlns:n1=\"http://commcarehq.org/xforms\">
        CommCare ODK, version \"2.12\"(30706). App v9. CommCare Version 2.12. Build 30706, built on: May-21-2014</n1:appVersion>")
    end

    it 'should have correct source attrib' do
      assert_response(201)
      expect(@form.reload.responses.first.source).to eq 'j2me'
    end
  end
end