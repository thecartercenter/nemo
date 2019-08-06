# frozen_string_literal: true

require "rails_helper"

feature "response search", js: true do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:user) { create(:user, role_name: "coordinator", admin: true) }
  let!(:form) { create(:form, name: "Form 1", question_types: %w[text]) }
  let!(:response1) { create(:response, user: user, form: form, answer_values: ["foo"]) }
  let!(:response2) { create(:response, user: user, form: form, answer_values: ["bar"]) }
  let(:codes) { Response.all.pluck(:shortcode).map(&:upcase) }

  scenario "search results" do
    login(user)
    visit "/en/m/#{mission.compact_name}/responses"
    expect(page).to have_content("Displaying all 2 Responses")
    expect(page).to have_content(form.name)
    expect(page).to have_content(codes[0])
    expect(page).to have_content(codes[1])

    # Working search.
    search_for("foo")
    expect(page).to have_content(codes[0])
    expect(page).not_to have_content(codes[1])

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

  context "with more complex data" do
    let!(:user2) { create(:user) }
    let!(:form2) { create(:form, name: "Form 2", question_types: %w[text]) }
    let!(:response3) { create(:response, user: user2, form: form2, answer_values: ["baz"]) }

    scenario "search filters" do
      login(user)
      visit "/en/m/#{mission.compact_name}/responses"

      search_for(%(foo))
      expect(page).to have_field("search", with: "foo")

      new_search_for(%(form:"Form 1"))
      expect(page).to have_field("search", with: "")
      expect(page).to have_css("#form-filter.active-filter", text: "Form (Form 1)")

      new_search_for(%(reviewed:YES))
      expect(page).to have_field("search", with: "")
      expect(page).to have_css("#reviewed-filter.active-filter", text: "Reviewed (Yes)")

      new_search_for(%(submitter:("#{user.name}" | "#{user2.name}") reviewed:0))
      expect(page).to have_field("search", with: "")
      expect(page).to have_css("#submitter-filter.active-filter", text: "Submitter (2 filters)")
      expect(page).to have_css("#reviewed-filter.active-filter", text: "Reviewed (No)")

      new_search_for(%(form:"Form 1"))
      expect(page).to have_content(codes[0])
      expect(page).to have_content(codes[1])
      expect(page).not_to have_content(codes[2])
      click_on("Question")
      expect(page).to have_content("Showing questions from Form 1 only.")
      click_on("Form (Form 1)")
      # Clear the form filter.
      find(".select2-selection__clear").click
      # The hint should still be there until the search is submitted.
      expect(page).to(have_css(".active-filter"))
      # Click off to dismiss the popover and automatically submit the search.
      find("h1").click
      expect(page).not_to have_css(".active-filter")
      expect(page).to have_content("Displaying all 3 Responses")
    end
  end
end
