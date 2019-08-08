# frozen_string_literal: true

require "rails_helper"

feature "question search", js: true do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:question1) { create(:question, name: "How many cheeses?") }
  let!(:question2) { create(:question, name: "How many pies?") }
  let!(:user) { create(:user, role_name: "coordinator", admin: true) }

  scenario "search results" do
    login(user)
    visit "/en/m/#{mission.compact_name}/questions"
    expect(page).to have_content("Displaying all 2 Questions")
    expect(page).to have_content(question1.code)
    expect(page).to have_content(question2.code)

    # Working search.
    search_for("cheese")
    expect(page).to have_content(question1.code)
    expect(page).not_to have_content(question2.code)

    # Failing search.
    search_for("bobby fisher")
    expect(page).to have_content("No Questions found")

    # Empty search.
    search_for("")
    expect(page).to have_content("Displaying all 2 Questions")

    # Search error.
    search_for("creepy:")
    expect(page).to have_content(
      "Error: Your search query could not be understood due to unexpected text near the end."
    )
  end

  scenario "search filters" do
    login(user)
    visit "/en/m/#{mission.compact_name}/questions"

    search_for(%(foo))
    expect(page).to have_field("search", with: "foo")

    # Filters UI shouldn't be active on this page.
    expect(page).not_to have_css("#form-filter")
  end
end
