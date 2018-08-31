# frozen_string_literal: true

require "rails_helper"

feature "responses index" do
  let(:user) { create(:user) }
  let(:form) { create(:form, :published, name: "TheForm", question_types: %w[text]) }

  before { login(user) }

  context "general index page display" do
    let(:response_link) { Response.first.decorate.shortcode }

    scenario "returning to index after response loaded via ajax", js: true do
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
    let!(:response1) { create(:response, user: user, form: form, answer_values: ["pants"]) }
    let!(:response2) { create(:response, user: user, form: form, answer_values: ["sweater"]) }

    before { form.c[0].question.update!(key: true) }

    scenario "key question values are shown in index" do
      click_link("Responses")
      expect(page).to have_content(form.c[0].code)
      expect(page).to have_content("pants")
      expect(page).to have_content("sweater")
    end
  end

  context "search" do
    let(:form) { create(:form, :published, question_types: %w[text]) }
    let(:response) do
      create(:response,
        user: user,
        form: form,
        reviewed: true,
        answer_values: ["pants in i-am-a-banana"]
      )
    end

    describe "with answer text" do
      scenario "works" do
        visit responses_path(
          locale: "en",
          mode: "m",
          mission_name: get_mission.compact_name,
          form_id: form.id
        )

        # and searches with the response shortcode
        fill_in "search_str", with: "pants"
        click_on "Search"

        # a scoped responses index page shows
        expect(page).to have_content("Responses")
        expect(current_url).to end_with("/responses?search=pants")
      end
    end

    describe "with short code" do

      before { response.update(shortcode: "i-am-a-banana") }

      scenario "user is permitted to edit response" do
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

      describe "enumerator" do
        let(:user) { create(:user, role_name: :enumerator) }

        scenario "user is not permitted to edit response" do
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
end
