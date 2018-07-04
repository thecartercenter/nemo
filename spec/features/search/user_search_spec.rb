# frozen_string_literal: true

require "rails_helper"

feature "user search", :sms do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:other_mission) { create(:mission) }
  let!(:actor) { create(:user, name: "Alpha", role_name: "coordinator", admin: true) }
  let!(:user1) { create(:user, name: "Bravo", role_name: "staffer") }
  let!(:user2) { create(:user, name: "Charlie", role_name: "enumerator") }
  let!(:user3) { create(:user, name: "Delta", role_name: "enumerator") }

  before do
    # We want user2 to be a staffer but not in our main mission.
    user2.assignments.create!(mission: other_mission, role: "staffer")

    login(actor)
  end

  scenario "search in mission context" do
    visit "/en/m/#{mission.compact_name}/users"
    expect(page).to have_content(/Displaying all \d+ Users/)
    expect_matches(%w[Alpha Bravo Charlie Delta])

    # General search
    search_for("Alpha")
    expect_matches("Alpha", but_not: %w[Bravo Charlie Delta])

    # We test role specially here because it is sensitive to scopes introduced by the controller.
    search_for("role:staffer")
    expect_matches("Bravo", but_not: %w[Alpha Charlie Delta])

    # Failing search
    search_for("bobby fisher")
    expect(page).to have_content("No Users found")

    # Empty search.
    search_for("")
    expect(page).to have_content(/Displaying all \d+ Users/)

    # Search error.
    search_for("creepy:")
    expect(page).to have_content("Error: Your search query could not be understood "\
      "due to unexpected text near the end.")
  end

  scenario "role search in admin mode context" do
    visit "/en/admin/users"
    search_for("role:staffer")
    expect_matches(%w[Bravo Charlie], but_not: %w[Alpha Delta])
  end
end
