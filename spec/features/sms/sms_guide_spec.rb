# frozen_string_literal: true

require "rails_helper"

feature "SMS Guide", js: true do
  let!(:user) { create(:user) }

  before do
    get_mission.setting.update!(preferred_locales_str: "en,fr,rw", incoming_sms_numbers_str: "+1234567890")
    login(user)
  end

  context "with smsable form" do
    context "when form is live" do
      let!(:form) do
        create(:form, :live, name: "SMS Form", smsable: true, question_types: %w[text])
      end

      scenario "happy path" do
        visit(sms_guide_form_path(form, mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        expect(page).to have_content("Text Question Title")
      end
    end

    context "when form is draft" do
      let!(:form) do
        create(:form, :draft, name: "SMS Form", smsable: true, question_types: %w[text])
      end

      scenario "shows error" do
        visit(sms_guide_form_path(form, mode: "m", mission_name: get_mission.compact_name, locale: "en"))
        expect(page).to have_flash_error("You can't view the SMS guide for the form 'SMS Form'")
        expect(page).not_to have_content("Text Question Title")
      end
    end
  end

  context "with Multilingual fields" do
    let!(:form) do
      create(:form, :live, name: "SMS Form", smsable: true,
                           question_types: %w[multilingual_text multilingual_text_with_user_locale])
    end

    around do |example|
      bool = Rails.configuration.action_view.raise_on_missing_translations
      ELMO::Application.configure do
        config.action_view.raise_on_missing_translations = false
      end
      example.run
      ELMO::Application.configure do
        config.action_view.raise_on_missing_translations = bool
      end
    end

    scenario "view :fr guide" do
      visit(sms_guide_form_path(form, mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      select("Français", from: "lang")
      expect(page).to have_content("Formulaire")
      expect(page).to have_content("fr: Text Question Title")
      expect(page).to have_content("fr: Question Hint")
    end

    scenario "view :rw guide" do
      visit(sms_guide_form_path(form, mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      select("Kinyarwanda", from: "lang")
      expect(page).to have_content("Paper")
      expect(page).to have_content("rw: Text Question Title")
      expect(page).to have_content("rw: Question Hint")
    end

    context "where current locale is different from preferred locale" do
      before { I18n.locale = :es }

      scenario "view :fr guide" do
        visit user_path(user, mode: "m", mission_name: get_mission.compact_name, locale: I18n.locale)
        expect(page).to have_content("Entregar")
        click_link "Formularios"
        click_link "Sms Guide"
        select("Français", from: "lang")
        expect(page).to have_content("Formulaire")
        expect(page).to have_content("fr: Text Question Title")
        expect(page).to have_content("fr: Question Hint")
      end

      scenario "view :rw guide" do
        visit user_path(user, mode: "m", mission_name: get_mission.compact_name, locale: I18n.locale)
        expect(page).to have_content("Entregar")
        click_link "Formularios"
        click_link "Sms Guide"
        select("Kinyarwanda", from: "lang")
        expect(page).to have_content("Paper")
        expect(page).to have_content("rw: Text Question Title")
        expect(page).to have_content("rw: Question Hint")
      end
    end
  end
end
