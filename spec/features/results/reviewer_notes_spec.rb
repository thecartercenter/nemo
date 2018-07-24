# frozen_string_literal: true

require "rails_helper"

feature "reviewer notes", js: true do
  let(:reviewer) { create(:user) }
  let(:enumerator) { create(:user, role_name: :enumerator) }
  let(:form) { create(:form, :published, question_types: %w[integer]) }
  let(:response) { create(:response, :is_reviewed, form: form, answer_values: [0], user: enumerator) }
  let(:notes) { response.reviewer_notes }

  scenario "should not be visible to normal users" do
    login(enumerator)
    visit(hierarchical_response_path(response,
      locale: "en", mode: "m", mission_name: get_mission.compact_name))
    expect(page).not_to have_content(notes)
  end

  scenario "should be visible to admin" do
    login(create(:user, admin: true))
    visit(hierarchical_response_path(response,
      locale: "en", mode: "m", mission_name: get_mission.compact_name))
    expect(page).to have_content(notes)
  end

  scenario "should be visible to staffer" do
    login(create(:user, role_name: :staffer))
    visit(hierarchical_response_path(response,
      locale: "en", mode: "m", mission_name: get_mission.compact_name))
    expect(page).to have_content(notes)
  end
end
