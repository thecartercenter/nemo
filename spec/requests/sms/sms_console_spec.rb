require 'spec_helper'

describe "sms console", :sms do
  let(:user) { get_user }
  let(:form) { create(:form, question_types: %w(integer), smsable: true).tap(&:publish!) }

  before do
    login(user)
  end

  it "going to the page to create a new sms should succeed" do
    get_s(new_sms_test_path(mission_name: get_mission.compact_name))
  end

  it "submitting a test sms should succeed" do
    post(sms_tests_path, sms_test: {from: user.phone, body: "#{form.code} 1.123"})
    expect(response.body).to match /\AYour response to form '.+' was received. Thank you!\z/
  end
end
