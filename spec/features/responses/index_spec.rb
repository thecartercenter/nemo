# frozen_string_literal: true

require "rails_helper"

feature "responses index", js: true do
  let(:actor) { create(:user) }
  let(:form) { create(:form, :live, name: "TheForm", question_types: %w[text]) }
  let(:mission) { get_mission }
  let(:responses_path) { "/en/m/#{mission.compact_name}/responses" }

  before do
    login(actor)
  end

  context "general index page display" do
    before do
      # No auto-refresh, we will trigger manually. Waiting for auto-reloads
      # is too flaky to work with Capybara.
      stub_const(ResponsesController, "REFRESH_INTERVAL", 0)
      stub_const(ResponsesController, "PER_PAGE", 3)
    end

    scenario "returning to index after response loaded via ajax", js: true do
      visit(responses_path)
      expect(page).to have_content("No Responses found")
      expect(page).not_to have_content("TheForm")

      # Create response and wait for it show up via AJAX
      create(:response, form: form)
      reload_table
      expect(page).to have_content("TheForm")

      # Click response and then go back. Should still be there!
      click_link(Response.first.decorate.shortcode)
      click_link("Responses")
      expect(page).to have_content("TheForm")
    end

    describe "select all behavior across ajax reloads" do
      let!(:responses) { create_list(:response, 7, form: form) }

      scenario "select all UI state should persist across table reloads" do
        visit(responses_path)
        # Select all, ensure persists
        find("a", text: "Select All", match: :prefer_exact).click
        expect(page).to have_content("All 3 Responses on this page are selected")
        reload_table
        expect(page).to have_content("All 3 Responses on this page are selected")

        # Select all pages, ensure persists
        click_on("Select all 7 Responses")
        expect(page).to have_content("All 7 Responses are selected")
        reload_table
        expect(page).to have_content("All 7 Responses are selected")

        # Uncheck one box, ensure persists
        all(".cb_col input")[1].click
        expect(page).not_to have_css(".alert")
        reload_table
        expect(page).not_to have_css(".alert")
      end
    end

    def reload_table
      old_reload_count = find("#reload-count").text
      execute_script("ELMO.responseListView.fetch();")
      expect(page).not_to have_content(old_reload_count)
    end
  end

  describe "existing responses" do
    let!(:response) do
      create(:response, user: actor, form: form, reviewed: true, answer_values: ["pants in i-am-a-banana"])
    end

    context "with key question" do
      before { form.c[0].question.update!(key: true) }

      scenario "key question values are shown in index" do
        visit(responses_path)
        click_link("Responses")
        expect(page).to have_content(form.c[0].code)
        expect(page).to have_content("pants")
        expect(page).to have_content("Responses")
      end
    end

    context "search" do
      describe "with answer text" do
        scenario "works" do
          visit(responses_path)
          fill_in(class: "search-str", with: "pants")
          click_on("Search")

          # a scoped responses index page shows
          expect(page).to have_content("Responses")
          expect(page).to have_content(response.shortcode.upcase)
          expect(current_url).to end_with("/responses?search=pants")
        end
      end

      describe "with short code" do
        before { response.update!(shortcode: "i-am-a-banana") }

        context "lowercase" do
          scenario "redirects correctly" do
            visit(responses_path)
            fill_in(class: "search-str", with: response.shortcode)
            click_on("Search")
            owner_can_see_edit_page
          end

          describe "enumerator" do
            let(:actor) { create(:user, role_name: :enumerator) }

            scenario "for user that can not edit response" do
              visit(responses_path)
              fill_in(class: "search-str", with: response.shortcode)
              click_on("Search")
              unauthorized_person_can_see_show_page
            end
          end
        end

        context "uppercase" do
          scenario "for user that can edit response" do
            visit(responses_path)
            fill_in(class: "search-str", with: response.shortcode.upcase)
            click_on("Search")
            owner_can_see_edit_page
          end

          describe "enumerator" do
            let(:actor) { create(:user, role_name: :enumerator) }

            scenario "redirects correctly" do
              visit(responses_path)
              fill_in(class: "search-str", with: response.shortcode.upcase)
              click_on("Search")
              unauthorized_person_can_see_show_page
            end
          end
        end

        def owner_can_see_edit_page
          expect(page).to have_content("Edit Response")
          expect(current_url).to end_with("responses/#{response.shortcode}/edit")
        end

        def unauthorized_person_can_see_show_page
          expect(page).to have_content("Response: #{response.shortcode.upcase}")
          expect(current_url).to end_with("responses/#{response.shortcode}")
        end
      end
    end
  end

  describe "bulk destroy", js: true do
    let(:actor) { create(:admin) }
    let!(:responses) { create_list(:response, 3, mission: mission) }

    scenario "works" do
      visit(responses_path)
      all("input.batch_op").each { |b| b.set(true) }
      accept_confirm { click_on("Delete") }
      expect(page).to have_content("3 responses deleted successfully")
    end
  end
end
