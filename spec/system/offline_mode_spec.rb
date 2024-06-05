# frozen_string_literal: true

require "rails_helper"

describe "offline mode" do
  let(:user) { create(:admin) }

  around do |example|
    ENV["NEMO_OFFLINE_MODE"] = offline_mode.to_s
    example.run
    ENV["NEMO_OFFLINE_MODE"] = "false"
  end

  context "offline mode on" do
    let(:offline_mode) { true }

    scenario "forgot password link" do
      visit "/"
      expect(page).not_to have_content("Forgot Password?")
    end

    scenario "broadcast links" do
      login(user)
      visit(broadcasts_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
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
