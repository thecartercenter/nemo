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
end
