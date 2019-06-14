# frozen_string_literal: true

require "rails_helper"

feature "response search", js: true do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:user) { create(:user, role_name: "coordinator", admin: true) }
  let!(:form) { create(:form, name: "Form 1", question_types: %w[text]) }
  let!(:response1) { create(:response, user: user, form: form, answer_values: ["foo"]) }
  let!(:response2) { create(:response, user: user, form: form, answer_values: ["bar"]) }

  scenario "search" do
    r1_code = response1.shortcode.upcase
    r2_code = response2.shortcode.upcase

    login(user)
    visit "/en/m/#{mission.compact_name}/responses"
    expect(page).to have_content("Displaying all 2 Responses")
    expect(page).to have_content(form.name)
    expect(page).to have_content(r1_code)
    expect(page).to have_content(r2_code)

    # Working search.
    search_for("foo")
    expect(page).to have_content(r1_code)
    expect(page).not_to have_content(r2_code)

    # Failing search.
    search_for("bobby fisher")
    expect(page).to have_content("No Responses found")

    # Empty search.
    search_for("")
    expect(page).to have_content("Displaying all 2 Responses")

    # Search error.
    search_for("creepy:")
    expect(page).to have_content(
      "Error: Your search query could not be understood due to unexpected text near the end."
    )
  end
end
