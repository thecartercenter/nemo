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

      # Include the commcare tag we use to distinguish j2me requests.
      # Note that we don't use the noauth system here because that is tested separately.
      submit_xml_response(:user => @user, :xml => "<#{@question.odk_code}>42</#{@question.odk_code}>")
    end

    it 'should have correct source attrib' do
      assert_response(201)
      expect(@form.reload.responses.first.source).to eq 'j2me'
    end
  end
end