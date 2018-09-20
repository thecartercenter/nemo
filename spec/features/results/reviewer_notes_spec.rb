# frozen_string_literal: true

require "rails_helper"

feature "reviewer notes", js: true do
  let(:reviewer) { create(:user) }
  let(:enumerator) { create(:user, role_name: :enumerator) }
  let(:form) { create(:form, :published, question_types: %w[integer]) }
  let(:response) { create(:response, :is_reviewed, form: form, answer_values: [0], user: enumerator) }
  let(:notes) { response.reviewer_notes }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  context "normal users" do
    before { login(enumerator) }

    scenario "should not be visible" do
      visit(response_path(response, params))
      expect(page).not_to have_content(notes)
    end
  end

  context "admin user" do
    before { login(create(:user, admin: true)) }

    scenario "should be visible" do
      visit(response_path(response, params))
      expect(page).to have_content(notes)
    end

    scenario "can submit notes" do
      visit(response_path(response, params))
      fill_in("Notes", with: "testing")
      click_button("Save")

      expect(response.reload.reviewer_notes).to eq "testing"
      expect(response.reload.reviewed).to eq true
    end

    scenario "can not submit answers" do
      visit(response_path(response, params))
      expect(page).to_not have_selector("[data-path='0'] input")
    end
  end

  context "staffer user" do
    before { login(create(:user, role_name: :staffer)) }

    scenario "should be visible" do
      visit(response_path(response, params))
      expect(page).to have_content(notes)
    end

    scenario "can submit notes" do
      visit(response_path(response, params))
      fill_in("Notes", with: "testing")
      click_button("Save")

      visit(response_path(response, params))
      input = find("#response_reviewer_notes")
      expect(input.value).to eq "testing"
    end
  end
end
