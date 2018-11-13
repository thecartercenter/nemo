require "rails_helper"

feature "password reset"  do
  let(:user) { create(:user) }

  context "if not logged in" do
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
      expect(old_tok).not_to eq user.reload.perishable_token
    end

    context "with user with email address" do
      it "should work when using login instead of email" do
        assert_difference("ActionMailer::Base.deliveries.size", +1) do
          request_password_reset(user.login)
          expect(page).to have_content("Success: Instructions to reset")
          expect(ActionMailer::Base.deliveries.last.to).to eq [user.email]
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

  context "if already logged in" do
    let(:user2) { create(:user) }

    before do
      login(user)
      user2.reset_perishable_token!
    end

    it "attempting to load edit should logout existing user" do
      visit "/en/password-resets/#{user2.perishable_token}/edit"
      expect(page).to have_content("please enter a new password for your account")
      visit "/en"
      expect(page).to have_css("h1", text: "Login")
    end
  end

  def request_password_reset(value)
    visit "/en/password-resets/new"
    fill_in "Email or Username", with: value
    click_button "Send"
  end
end
