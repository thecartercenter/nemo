require "spec_helper"

feature "responses index" do
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
