# frozen_string_literal: true

require "rails_helper"

feature "settings regenerable fields", js: true do
  include_context "regenerable fields"

  let!(:mission) { get_mission }
  let!(:user) { create(:user, role_name: :coordinator, mission: get_mission) }

  before do
    login(user)
  end

  describe "override code" do
    scenario "can regenerate" do
      visit("/en/m/#{mission.compact_name}/settings")
      expect_token_regenerated(".setting_override_code", existing: false)
    end
  end

  describe "incoming sms token" do
    scenario "can regenerate" do
      visit("/en/m/#{mission.compact_name}/settings")
      emails = emails_sent_by { expect_token_regenerated(".setting_incoming_sms_token") }
      expect(emails.length).to eq(1)

      email = emails.first
      expect(email.body.to_s).to match(/#{mission.name}/)
      expect(email.body.to_s).not_to match(/translation_missing/)
    end
  end
end
