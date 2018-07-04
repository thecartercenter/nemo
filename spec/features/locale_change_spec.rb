# encoding: utf-8
require 'rails_helper'

feature 'locale change', js: true do
  before do
    @user = create(:user)
    @form = create(:sample_form)
    @form.publish!
    login(@user)
  end

  scenario 'should work' do
    # We land on the user profile page after login.
    expect(page).to have_selector('h1', text: /^Profile:/)

    # Change language on main page.
    click_link('Change Language')
    select('Français', from: 'locale')
    expect(page).to have_selector('h1', text: /^Profil:/)

    # Test page with query string.
    click_link('Soumettre')
    click_link(@form.name)
    expect(page).to have_selector('h1', text: 'Nouvelle réponse')
    expect(current_url).to end_with("responses/new?form_id=#{@form.id}")

    # URL ending shouldn't change on link
    click_link('Changer la langue')
    select('English', from: 'locale')
    expect(page).to have_selector('h1', text: 'New Response')
    expect(current_url).to end_with("responses/new?form_id=#{@form.id}")
  end
end
