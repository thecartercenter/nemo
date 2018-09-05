# frozen_string_literal: true

require "rails_helper"

feature "responses index" do
  let(:user) { create(:user) }
  let(:form) { create(:form, :published, name: "TheForm", question_types: %w[text]) }

  before do
    login(user)
    click_on "Responses"
  end

  context "general index page display" do
    let(:response_link) { Response.first.decorate.shortcode }

    scenario "returning to index after response loaded via ajax", js: true do
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

  describe "existing responses" do
    let!(:response) do
      create(
        :response,
        user: user,
        form: form,
        reviewed: true,
        answer_values: ["pants in i-am-a-banana"]
      )
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
          fill_in("search_str", with: "pants")
          click_on("Search")

          # a scoped responses index page shows
          expect(page).to have_content("Responses")
          expect(page).to have_content(response.shortcode.upcase)
          expect(current_url).to end_with("/responses?search=pants")
        end
      end

      describe "with short code" do
        before do
          response.update!(shortcode: "i-am-a-banana")

          fill_in("search_str", with: response.shortcode)
          click_on("Search")
        end

        scenario "for user that can edit response" do
          # the response edit page shows
          expect(page).to have_content("Edit Response")
          expect(current_url).to end_with("responses/#{response.shortcode}/edit")
        end

        describe "enumerator" do
          let(:user) { create(:user, role_name: :enumerator) }

          scenario "for user that can not edit response" do
            # the response show page shows
            expect(page).to have_content("Response: #{response.shortcode.upcase}")
            expect(current_url).to end_with("responses/#{response.shortcode}")
          end
        end
      end
    end
  end
end
