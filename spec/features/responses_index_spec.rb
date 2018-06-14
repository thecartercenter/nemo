require "spec_helper"

feature "responses index" do
  context 'general index page display' do
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

  context 'multiple entries and data check' do
    let!(:admin) { create(:admin) }
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }
    let(:form) { create(:form, :published, question_types: %w(integer)) }
    let!(:response_1) { create(:response, user: user_1, form: form, answer_values: [1]) }
    let!(:response_2) { create(:response, user: user_2, form: form, answer_values: [2]) }
    let(:response_link) { Response.first.decorate.shortcode }

    scenario 'display all responses with values' do
      login(admin)
      click_link("Responses")
      expect(page).to have_content(response_1.answers.first.value)
      expect(page).to have_content(response_2.answers.first.value)
    end
  end
end
