require 'test_helper'

class SmsConsoleTest < ActionDispatch::IntegrationTest

  test "going to the page to create a new sms should succeed" do
    user = get_user
    login(user)

    get "/m/#{get_mission.compact_name}/sms-tests/new"

    assert_response :success
  end

end
