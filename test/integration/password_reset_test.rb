require 'test_helper'

# this class contains tests for creating/updating/deleting users/assignments
class PasswordResetTest < ActionDispatch::IntegrationTest

  test "password reset page should load" do
    get(new_password_reset_path)
    assert_response(:success)
  end

  test "submitting password reset form should reset perishable token and send email" do
    @user = FactoryGirl.create(:user)
    old_tok = @user.perishable_token

    # should be redirected to login
    assert_difference('ActionMailer::Base.deliveries.size', +1) do
      post(password_resets_path, {:password_reset => {:email => @user.email}})
    end

    assert_not_equal(old_tok, @user.reload.perishable_token)

    assert_redirected_to(login_url)
    follow_redirect!
  end
end