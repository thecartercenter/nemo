require 'test_helper'

class SmsTestsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "going to the page to create a new sms should succeed" do
    user = get_user
    assert UserSession.create(user.login)

    get :new

    assert_response :success
  end

end
