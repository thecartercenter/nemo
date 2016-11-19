require "spec_helper"

feature "SMS Guide", js: true do
  let!(:user) { create(:user) }
  let!(:mission) { get_mission.setting.update_attributes!(preferred_locales_str: "en,fr,rw") }

  before { login(user) }

  context "with SMSable form" do
    let!(:form) { create(:form, name: "SMS Form", smsable: true, mission: get_mission, question_types: %w(text)).publish! }

    scenario "happy path" do
      click_link "Forms"
      click_link "SMS Guide"
      expect(page).to have_content "Text Question Title"
    end
  end

  context "with Multilingual fields" do
    let!(:form) {
      create(:form, name: "SMS Form", smsable: true, mission: get_mission,
        question_types: %w(multilingual_text multilingual_text_with_user_locale) ).publish!
    }

    scenario "view :fr guide" do
      click_link "Forms"
      click_link "SMS Guide"
      select("Français", from: "lang")
      expect(page).to have_content "fr: Text Title"
      expect(page).to have_content "fr: Question Hint"
    end

    scenario "view :rw guide" do
      click_link "Forms"
      click_link "SMS Guide"
      select("Kinyarwanda", from: "lang")
      expect(page).to have_content "rw: Text Title"
      expect(page).to have_content "rw: Question Hint"
    end
  end
end
