# frozen_string_literal: true

require "rails_helper"

feature "sms settings form", :sms do
  let(:mission) { create(:mission) }
  let(:user) { create(:user, admin: true) }

  before do
    login(user)
  end

  context "twilio" do
    context "with no prior twilio settings" do
      before do
        mission.setting.update!(default_outgoing_sms_adapter: nil, twilio_phone_number: nil,
                                twilio_account_sid: nil, twilio_auth_token: nil)
      end

      scenario "filling in account sid only should error" do
        visit("/en/m/#{mission.compact_name}/settings")
        fill_in("setting_twilio_account_sid", with: "abc")
        click_button("Save")
        expect(page).to have_content("Settings are invalid (see below).")
        expect(find("#twilio_auth_token1 .form-errors")).to have_content("This field is required.")
      end

      scenario "filling in auth token only should error" do
        visit("/en/m/#{mission.compact_name}/settings")
        click_link("Change Auth Token")
        fill_in("setting_twilio_auth_token1", with: "abc")
        click_button("Save")
        expect(page).to have_content("Settings are invalid (see below).")
        expect(find("#twilio_account_sid .form-errors")).to have_content("This field is required.")
      end

      scenario "filling in both should work" do
        visit("/en/m/#{mission.compact_name}/settings")
        fill_in("setting_twilio_account_sid", with: "abc")
        click_link("Change Auth Token")
        fill_in("setting_twilio_auth_token1", with: "jfjfjfjf")
        click_button("Save")
        expect(page).to have_content("Settings updated successfully")
        expect(find("#setting_twilio_account_sid").value).to eq("abc")
        expect(find("#setting_twilio_auth_token1").value).to eq(nil)
      end
    end
  end

  context "generic sms" do
    scenario "filling in sms settings should catch errors and work" do
      visit("/en/m/#{mission.compact_name}/settings")
      fill_in("setting_generic_sms_config_str", with: "{")
      click_button("Save")

      expect(page).to have_content("JSON error:")
      fill_in("setting_generic_sms_config_str", with: '{"params":{"body":"msg","from":"tel"},
        "response": "x", "matchHeaders": {"User-Agent": "Thing"}}')
      click_button("Save")

      # Ensure save was successful.
      expect(page).to have_content("Settings updated successfully")
      expect(find("#setting_generic_sms_config_str").value).to match(/"params":/)
    end
  end

  context "admin mode" do
    # Some SMS settings are visible in admin mode
    scenario "filling in twilio settings should work" do
      visit("/en/admin/settings")
      expect(page).not_to have_content("Frontline SMS")
      expect(page).not_to have_content("Generic SMS")
      fill_in("setting_twilio_account_sid", with: "abc")
      click_link("Change Auth Token")
      fill_in("setting_twilio_auth_token1", with: "jfjfjfjf")
      click_button("Save")
      expect(page).to have_content("Settings updated successfully")
      expect(find("#setting_twilio_account_sid").value).to eq("abc")
      expect(find("#setting_twilio_auth_token1").value).to eq(nil)
    end
  end
end
