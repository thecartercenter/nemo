require "spec_helper"

feature "offline mode" do
  let(:user) { create(:admin) }

  context "offline mode on" do
    around do |example|
      configatron.offline_mode = true
      example.run
      configatron.offline_mode = false
    end

    scenario "forgot password link" do
      visit "/"
      expect(page).not_to have_content("Forgot Password?")
    end

    scenario "broadcast links" do
      login(user)
      click_on("Broadcasts")
      expect(page).not_to have_content("Send Broadcast")
      click_on("Users")
      expect(page).not_to have_content("Send Broadcast")
    end

    scenario "email not sent" do
      expect { AdminMailer.error(StandardError.new).deliver_now }.to(
        change { ActionMailer::Base.deliveries.size }.by(0))
    end
  end

  context "offline mode off" do
    scenario "email sent" do
      expect { AdminMailer.error(StandardError.new).deliver_now }.to(
        change { ActionMailer::Base.deliveries.size }.by(1))
    end
  end
end
