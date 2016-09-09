require "spec_helper"

feature "sms settings form", :sms do
  let(:mission){ create(:mission, setting: setting) }
  let(:user){ create(:user, admin: true) }

  before do
    login(user)
  end

  context "twilio" do
    context "with no prior settings" do
      let(:setting){ build(:setting, twilio_phone_number: nil, twilio_account_sid: nil, twilio_auth_token: nil) }

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
        expect(find('#setting_twilio_account_sid').value).to eq "abc"
        expect(find('#setting_twilio_auth_token1').value).to eq nil
      end
    end
  end
end
