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
      submit_xml_response(:user => @user, :xml => %Q{
        <#{@question.odk_code}>42</#{@question.odk_code}>
        <n0:meta xmlns:n0="http://openrosa.org/jr/xforms">
          <n0:deviceID>A000002C551BFA</n0:deviceID>
          <n0:timeStart>2014-06-03T09:14:18.550-04</n0:timeStart>
          <n0:timeEnd>2014-06-03T09:14:34.975-04</n0:timeEnd>
          <n0:username>commcare</n0:username>
          <n0:userID>a6badac977fcb30220518072c1aa6365</n0:userID>
          <n0:instanceID>a9e9984a-f06f-491e-a5d9-03d951b4105e</n0:instanceID>
          <n1:appVersion xmlns:n1="http://commcarehq.org/xforms">
            CommCare ODK, version "2.12"(30706). App v9. CommCare Version 2.12. Build 30706, built on: May-21-2014
          </n1:appVersion>
        </n0:meta>
      })
    end

    it 'should have correct source attrib' do
      assert_response(201)
      expect(@form.reload.responses.first.source).to eq 'j2me'
    end
  end
end