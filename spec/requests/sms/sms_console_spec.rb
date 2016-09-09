require 'spec_helper'

describe "sms console", :sms do
  it "going to the page to create a new sms should succeed" do
    user = get_user
    login(user)
    get_s(new_sms_test_path(mission_name: get_mission.compact_name))
  end
end
