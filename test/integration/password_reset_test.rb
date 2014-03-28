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

  test "password reset generated in admin mode should generate correct email" do
    @admin = FactoryGirl.create(:user, :admin => true)
    login(@admin)

    # make sure email gets sent
    assert_difference('ActionMailer::Base.deliveries.size', +1) do
      # create a new user, sending password instr to email
      post(users_path(:admin_mode => 'admin'), "user"=>{
        "name"=>"Alberto Ooooh",
        "login"=>"aooooh",
        "email"=>"foo@example.com",
        "assignments_attributes"=>{"1"=>{"id"=>"", "_destroy"=>"false", "mission_id"=>get_mission.id, "role"=>"observer"}},
        "reset_password_method"=>"email"
      })
      assert_redirected_to(users_path(:admin_mode => 'admin'))
      follow_redirect!
      assert_response(:success)
    end

    # make sure url is correct
    # first get the url
    email = ActionMailer::Base.deliveries.first
    url = email.body.match(/https?:.+\/edit/).to_s

    # make sure we actually found it
    assert_match(/^http/, url)

    # ensure no /admin/ chunk in email
    assert_not_match("/admin/", url)

    # ensure no missing translations
    assert_not_match(/translation_missing/, email.body.to_s)
  end
end