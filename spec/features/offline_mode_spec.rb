# frozen_string_literal: true

require "rails_helper"

feature "offline mode" do
  let(:user) { create(:admin) }

  around do |example|
    configatron.offline_mode = offline_mode
    example.run
    configatron.offline_mode = false
  end

  context "offline mode on" do
    let(:offline_mode) { true }

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
      expect { ExceptionNotifier.notify_exception(StandardError.new) }.to(
        change { ActionMailer::Base.deliveries.size }.by(0)
      )
    end
  end

  context "offline mode off" do
    let(:offline_mode) { false }

    scenario "email sent" do
      expect { ExceptionNotifier.notify_exception(StandardError.new) }.to(
        change { ActionMailer::Base.deliveries.size }.by(1)
      )
    end
  end
end
