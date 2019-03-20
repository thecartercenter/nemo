# frozen_string_literal: true

require "rails_helper"

feature "responses index", js: true do
  let(:user) { create(:user) }
  let(:form) { create(:form, :published, name: "TheForm", question_types: %w[text]) }

  before do
    login(user)
    click_on("Responses")
  end

  context "general index page display" do
    let(:response_link) { Response.first.decorate.shortcode }

    around do |example|
      ENV["RESPONSE_REFRESH_INTERVAL"] = "1000"
      example.run
      ENV.delete("RESPONSE_REFRESH_INTERVAL")
    end

    scenario "returning to index after response loaded via ajax", js: true do
      expect(page).to have_content("No Responses found")
      expect(page).not_to have_content("TheForm")

      # Create response and wait for it show up via AJAX
      create(:response, form: form)
      expect(page).to have_content("TheForm")

      # Click response and then go back. Should still be there!
      click_link(response_link)
      click_link("Responses")
      expect(page).to have_content("TheForm")
    end
  end

  describe "existing responses" do
    let!(:response) do
      create(:response, user: user, form: form, reviewed: true, answer_values: ["pants in i-am-a-banana"])
    end

    context "with key question" do
      before { form.c[0].question.update!(key: true) }

      scenario "key question values are shown in index" do
        click_link("Responses")
        expect(page).to have_content(form.c[0].code)
        expect(page).to have_content("pants")
        expect(page).to have_content("Responses")
      end
    end

    context "search" do
      describe "with answer text" do
        scenario "works" do
          fill_in("search-str", with: "pants")
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
          before do
            fill_in("search-str", with: response.shortcode)
            click_on("Search")
          end

          scenario "redirects correctly" do
            owner_can_see_edit_page
          end

          describe "enumerator" do
            let(:user) { create(:user, role_name: :enumerator) }

            scenario "for user that can not edit response" do
              unauthorized_person_can_see_show_page
            end
          end
        end

        context "uppercase" do
          before do
            fill_in("search-str", with: response.shortcode.upcase)
            click_on("Search")
          end

          scenario "for user that can edit response" do
            # the response edit page shows
            owner_can_see_edit_page
          end

          describe "enumerator" do
            let(:user) { create(:user, role_name: :enumerator) }

            scenario "redirects correctly" do
              # the response show page shows
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

  describe "batch delete", js: true do
    let(:admin) { create(:admin) }
    let(:mission) { get_mission }
    let!(:responses) { create_list(:response, 3, mission: mission) }

    before do
      login(admin)
    end

    scenario "works" do
      visit("/en/m/#{mission.compact_name}/responses")
      all("input.batch_op").each { |b| b.set(true) }
      accept_confirm { click_on("Delete Selected") }
      expect(page).to have_content("3 responses deleted successfully")
    end
  end
end
