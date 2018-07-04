require "rails_helper"

feature "translatable strings" do
  let(:user) { create(:user, admin: true) }
  let(:question) { create(:question, name_translations: {en: "FooBar"}) }

  before do
    login(user)

    # Simulate switching mission to French-only.
    # Question above with only English translation should show as blank.
    question.mission.setting.update_attributes!(preferred_locales_str: "fr")
  end

  scenario "should only fallback to other locales if in preferred_locales" do
    visit "/en/m/#{question.mission.compact_name}/questions"
    expect(page).to have_content("Displaying 1 Question")
    expect(page).not_to have_content("FooBar")

    # Go away from page.
    click_link("Option Sets")
    expect(page).to have_content("No Option Sets")

    # Check it again to make sure the locale restrictions didn't stop working after first request.
    click_link("Questions")
    expect(page).to have_content("Displaying 1 Question")
    expect(page).not_to have_content("FooBar")

    # Enable English
    click_link("Settings")
    fill_in("Preferred Languages:", with: "en,fr")
    click_on("Save")

    click_link("Questions")
    expect(page).to have_content("FooBar")
  end
end
