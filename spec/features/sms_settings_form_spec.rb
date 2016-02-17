require "spec_helper"

feature "sms settings form" do
  let(:mission){ create(:mission, setting: setting) }
  let(:user){ create(:user, admin: true) }

  before do
    login(user)
  end

  context "intellisms" do
    context "with no prior settings" do
      let(:setting){ build(:setting, intellisms_username: nil, intellisms_password: nil) }

      scenario "filling in username only should error" do
        visit("/en/m/#{mission.compact_name}/settings")
        fill_in("setting_intellisms_username", with: "abc")
        click_button("Save")
        expect(page).to have_content("Settings are invalid (see below).")
        expect(find("#intellisms_password1 .form-errors")).to have_content("This field is required.")
      end

      scenario "filling in password only should error" do
        visit("/en/m/#{mission.compact_name}/settings")
        fill_in("setting_intellisms_password1", with: "abc")
        click_button("Save")
        expect(page).to have_content("Settings are invalid (see below).")
        expect(find("#intellisms_username .form-errors")).to have_content("This field is required.")
        expect(find("#intellisms_password1 .form-errors")).to have_content("match")
      end

      scenario "filling in both should work" do
        visit("/en/m/#{mission.compact_name}/settings")
        fill_in("setting_intellisms_username", with: "abc")
        fill_in("setting_intellisms_password1", with: "jfjfjfjf")
        fill_in("setting_intellisms_password2", with: "jfjfjfjf")
        click_button("Save")
        expect(page).to have_content("Settings updated successfully")
        expect(find('#setting_intellisms_username').value).to eq "abc"
        expect(find('#setting_intellisms_password1').value).to eq nil
        expect(find('#setting_intellisms_password2').value).to eq nil
      end
    end
  end
end
