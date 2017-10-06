require "spec_helper"

feature "SMS Guide", js: true do
  let!(:user) { create(:user) }
  let!(:mission) { get_mission.setting.update_attributes!(preferred_locales_str: "en,fr,rw") }

  before { login(user) }

  context "with SMSable form" do
    let!(:form) do
      create(:form, name: "SMS Form", smsable: true, mission: get_mission, question_types: %w(text)).publish!
    end

    scenario "happy path" do
      click_link "Forms"
      click_link "SMS Guide"
      expect(page).to have_content "Text Question Title"
    end
  end

  context "with Multilingual fields" do
    let!(:form) do
      create(:form,
        name: "SMS Form",
        smsable: true,
        mission: get_mission,
        question_types: %w(multilingual_text multilingual_text_with_user_locale) ).publish!
    end

    scenario "view :fr guide" do
      click_link "Forms"
      click_link "SMS Guide"
      select("Français", from: "lang")
      expect(page).to have_content "Formulaire"
      expect(page).to have_content "fr: Text Question Title"
      expect(page).to have_content "fr: Question Hint"
    end

    scenario "view :rw guide" do
      click_link "Forms"
      click_link "SMS Guide"
      select("Kinyarwanda", from: "lang")
      expect(page).to have_content ".instructions.paper"
      expect(page).to have_content "rw: Text Question Title"
      expect(page).to have_content "rw: Question Hint"
    end

    context "where current locale is different from preferred locale" do
      around(:each) do |example|
        I18n.locale = :es
        example.run
        I18n.locale = :en
      end

      scenario "view :fr guide" do
        visit user_path(user, mode: "m", mission_name: get_mission.compact_name, locale: I18n.locale)
        expect(page).to have_content "Entregar"
        click_link "Formularios"
        click_link "SMS Guide"
        select("Français", from: "lang")
        expect(page).to have_content "Formulaire"
        expect(page).to have_content "fr: Text Question Title"
        expect(page).to have_content "fr: Question Hint"
      end

      scenario "view :rw guide" do
        visit user_path(user, mode: "m", mission_name: get_mission.compact_name, locale: I18n.locale)
        expect(page).to have_content "Entregar"
        click_link "Formularios"
        click_link "SMS Guide"
        select("Kinyarwanda", from: "lang")
        expect(page).to have_content ".instructions.paper"
        expect(page).to have_content "rw: Text Question Title"
        expect(page).to have_content "rw: Question Hint"
      end
    end
  end
end
