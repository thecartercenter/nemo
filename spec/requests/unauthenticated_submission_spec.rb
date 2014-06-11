require 'spec_helper'
require 'fileutils'

describe 'unauthenticated submissions', :type => :request do

  context 'to mission where they are not allowed' do
    before do
      # Allow flag defaults to zero
      @mission = FactoryGirl.create(:mission)
      @submission_url = "/m/#{@mission.compact_name}/noauth/submission"
    end

    it 'should be rejected' do
      post(@submission_url)
      assert_response(:unauthorized)
      expect(response.body).to eq('UNAUTHENTICATED_SUBMISSIONS_NOT_ALLOWED')
    end
  end

  context 'to a mission where they are allowed' do
    before do
      @mission = get_mission
      @mission.setting.update_attributes!(:allow_unauthenticated_submissions => true)
      @submission_url = "/m/#{@mission.compact_name}/noauth/submission"
      @form = FactoryGirl.create(:form, :mission => @mission, :question_types => %w(integer))
      @form.publish!
      @question = @form.questions.first
    end

    context 'with a valid username embedded' do
      before do
        @user = FactoryGirl.create(:user, :role_name => :observer)
        submit_xml_response("<#{@question.odk_code}>42</#{@question.odk_code}><n0:username>#{@user.login}</n0:username>")
      end

      it 'should set correct user' do
        expect(controller.current_user).to eq @user
      end

      it 'should succeed in creating response' do
        assert_response(201)
        expect(@question.reload.answers.first.value).to eq '42'
      end
    end

    context 'with no submission file' do
      before do
        post(@submission_url, :format => 'xml')
      end

      it 'should return 422' do
        assert_response(422)
        expect(response.body).to eq 'SUBMISSION_DATA_MISSING'
      end
    end

    context 'with no username embedded' do
      before do
        submit_xml_response('')
      end

      it 'should return 401' do
        assert_response(401)
        expect(response.body).to eq 'USERNAME_NOT_SPECIFIED'
      end
    end

    context 'with invalid username embedded' do
      before do
        submit_xml_response('<data><n0:username>foo</n0:username>')
      end

      it 'should return 401' do
        assert_response(401)
        expect(response.body).to eq 'USER_NOT_FOUND'
      end
    end

    context 'with user not able to access mission' do
      before do
        other_mission = FactoryGirl.create(:mission, :name => 'Other mission')
        @user = FactoryGirl.create(:user, :role_name => :observer, :mission => other_mission)
        submit_xml_response("<n0:username>#{@user.login}</n0:username>")
      end

      it 'should return 401' do
        assert_response(401)
        expect(response.body).to eq 'USER_CANT_ACCESS_MISSION'
      end
    end
    # should set source to j2me
  end
end