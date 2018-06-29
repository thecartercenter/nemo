require 'rails_helper'

describe "sms console", :sms do
  let(:user) { get_user }
  let(:mission_name) { get_mission.compact_name }
  let(:form) { create(:form, question_types: qtypes, smsable: true).tap(&:publish!) }

  before do
    login(user)
  end

  context "with integer form" do
    let(:qtypes) { %w(integer) }

    it "going to the page to create a new sms should succeed" do
      get_s("/en/m/#{mission_name}/sms-tests/new")
    end

    it "submitting a test sms should succeed" do
      post("/en/m/#{mission_name}/sms-tests", params: {sms_test: {from: user.phone, body: "#{form.code} 1.123"}})
      expect(response.body).to match /\AYour response to form '.+' was received. Thank you!\z/
    end
  end

  context "with datetime form" do
    let(:qtypes) { %w(datetime) }

    before do
      get_mission.setting.update!(timezone: "Saskatchewan")
    end

    it "submitting a test sms should store the date in the right timezone" do
      post("/en/m/#{mission_name}/sms-tests",
        params: {sms_test: {from: user.phone, body: "#{form.code} 1.201701011230"}})
      expect(Answer.first.datetime_value.to_s).to eq "2017-01-01 12:30:00 -0600"
    end
  end
end
