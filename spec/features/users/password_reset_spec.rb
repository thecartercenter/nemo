# frozen_string_literal: true

require "rails_helper"

feature "password reset" do
  let(:user) { create(:user) }

  context "if not logged in" do
    describe "reset request" do
      context "with user with email address" do
        it "new password reset page should load" do
          visit "/en/password-resets/new"
          expect(page).to have_content("Enter your email")
        end

        it "submitting password reset form should reset perishable token and send email" do
          old_tok = user.perishable_token
          assert_difference("ActionMailer::Base.deliveries.size", +1) do
            request_password_reset(user.email)
            expect(page).to have_content("Success: Instructions to reset")
          end
          expect(old_tok).not_to eq(user.reload.perishable_token)
        end

        it "should not automatically reset password" do
          crypted_password = user.crypted_password
          request_password_reset(user.email)
          expect(user.reload.crypted_password).to eq(crypted_password)
        end

        it "should work when using login instead of email" do
          assert_difference("ActionMailer::Base.deliveries.size", +1) do
            request_password_reset(user.login)
            expect(page).to have_content("Success: Instructions to reset")
            expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
          end
        end
      end

      context "with user with no email address" do
        let(:user) { create(:user, :no_email) }

        it "should show error when using login instead of email" do
          assert_difference("ActionMailer::Base.deliveries.size", 0) do
            request_password_reset(user.login)
            expect(page).to have_content("There is no email address associated with that account")
          end
        end
      end

      context "with ambiguous email address" do
        let(:users) { create_list(:user, 2, email: "foo@bar.com") }

        it "should show special error" do
          assert_difference("ActionMailer::Base.deliveries.size", 0) do
            request_password_reset(users.first.email)
            expect(page).to have_content("There are multiple accounts associated with that email address")
          end
        end
      end
    end

    describe "password update" do
      before do
        user.reset_perishable_token!
      end

      context "with new password" do
        it "should change password and log in user" do
          visit("/en/password-resets/#{user.perishable_token}/edit")
          expect(page).to have_content("please enter a new password for your account")
          fill_in("Password", with: "newpasswordX123;")
          fill_in("Retype Password", with: "newpasswordX123;")
          click_on("Send")
          expect(page).to be_logged_in
          logout

          real_login(user, "newpasswordX123;")
          expect(page).to be_logged_in
        end
      end

      context "with invalid password" do
        it "should show validation message" do
          visit("/en/password-resets/#{user.perishable_token}/edit")
          fill_in("Password", with: "x")
          fill_in("Retype Password", with: "x")
          click_on("Send")
          expect(page).to have_content("please enter a new password for your account")
          expect(page).to have_content("Password must include at least")
        end
      end

      context "with inactive account" do
        before do
          user.activate!(false)
        end

        it "should redirect to login page after reset with flash" do
          visit("/en/password-resets/#{user.perishable_token}/edit")
          fill_in("Password", with: test_password)
          fill_in("Retype Password", with: test_password)
          click_on("Send")
          expect(page).not_to be_logged_in
          expect(page).to have_title("Login")
          expect(page).to have_flash_error("Password updated successfully, but your account is not active,")
        end
      end
    end
  end

  context "if already logged in" do
    let(:user2) { create(:user) }

    before do
      user2.reset_perishable_token!
    end

    it "attempting to load edit should logout existing user" do
      real_login(user)
      visit("/en/password-resets/#{user2.perishable_token}/edit")
      expect(page).to have_content("please enter a new password for your account")
      visit("/en")
      expect(page).to have_css("h1", text: "Login")
    end
  end

  def request_password_reset(value)
    visit("/en/password-resets/new")
    fill_in("Email or Username", with: value)
    click_button("Send")
  end
end
