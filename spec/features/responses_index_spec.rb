# frozen_string_literal: true

require "rails_helper"

feature "responses index" do
  context "general index page display" do
    let(:user) { create(:user) }
    let(:form) { create(:form, :published, name: "TheForm") }
    let(:response_link) { Response.first.decorate.shortcode }

    scenario "returning to index after response loaded via ajax", js: true do
      login(user)
      click_link("Responses")
      expect(page).not_to have_content("TheForm")

      # Create response and make it show up via AJAX
      create(:response, form: form)
      page.execute_script("responses_fetch();")
      expect(page).to have_content("TheForm")

      # Click response and then go back. Should still be there!
      click_link(response_link)
      click_link("Responses")
      expect(page).to have_content("TheForm")
    end
  end

  context "with key question" do
    let(:user) { create(:user) }
    let(:form) { create(:form, :published, question_types: %w[text]) }
    let!(:response1) { create(:response, user: user, form: form, answer_values: ["pants"]) }
    let!(:response2) { create(:response, user: user, form: form, answer_values: ["sweater"]) }

    before do
      form.c[0].question.update!(key: true)
    end

    scenario "key question values are shown in index" do
      login(user)
      click_link("Responses")
      expect(page).to have_content(form.c[0].code)
      expect(page).to have_content("pants")
      expect(page).to have_content("sweater")
    end
  end

  # Do the check for if it's a short code in the controller
  # Add happy path spec for regular search
  # Do file refactor

  # Response match
    # Permitted
      # Response#edit
      # Test for shortcode being in a string/text
    # Not permitted
      # Response#show
      # Test for shortcode being in a string/text
  context "search" do
    let(:user) { create(:user) }
    let(:reviewer) { create(:user, role_name: :reviewer) }
    let(:form) { create(:form, :published, question_types: %w[text]) }
    let!(:response) { create(:response, user: user, form: form, answer_values: ["pants"]) }

    describe "with short code" do
      scenario "user is permitted to see response" do
        # when the owner of a response is logged in
        login(user)

        visit responses_path(
          locale: "en",
          mode: "m",
          mission_name: get_mission.compact_name,
          form_id: form.id
        )

        # and searches with the response shortcode
        fill_in "search_str", with: response.shortcode
        click_on "Search"

        # the response edit page shows
        expect(page).to have_content("Edit Response")
        expect(current_url).to end_with("responses/#{response.shortcode}/edit")
      end

      scenario "user is not permitted to see response" do
        # when a reviewer is logged in
        login(reviewer)

        visit responses_path(
          locale: "en",
          mode: "m",
          mission_name: get_mission.compact_name,
          form_id: form.id
        )

        # and searches with the response shortcode
        fill_in "search_str", with: response.shortcode
        click_on "Search"

        # the response show page shows
        expect(page).to have_content("Response: #{response.shortcode.upcase}")
        expect(current_url).to end_with("responses/#{response.shortcode}")
      end
    end
  end
end
