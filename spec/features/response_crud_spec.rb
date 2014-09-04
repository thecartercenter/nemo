require 'spec_helper'

feature 'response crud', js: true do
  before do
    @user = create(:user)
    @form = create(:sample_form)
    @form.publish!
    visit login_path(locale: 'en')
    fill_in 'Username', with: @user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
  end

  scenario 'should work' do
    click_link('Submit')
    click_link(@form.name)
    expect(page).to have_selector('h1', 'New Response')
    select(@user.name, from: 'response_user_id')

    # Fill in answers
    select('Dog', from: 'response_answer_sets_0_answers_0_option_id')
    select('Plant', from: 'response_answer_sets_1_answers_0_option_id')
    select('Oak', from: 'response_answer_sets_1_answers_1_option_id')

    # Save and check it worked.
    click_button('Save')
    expect(page).to have_selector('h1', 'Response')

    # Check show mode.
    click_link(Response.first.id.to_s)
    %w(Dog Plant Oak).each{ |o| expect(page).to have_selector('div.option-name', text: o) }

    # Check edit mode.
    click_link('Edit Response')
    select('Animal', from: 'response_answer_sets_1_answers_0_option_id')
    select('Cat', from: 'response_answer_sets_1_answers_1_option_id')
    click_button('Save')

    # Check that change occurred.
    click_link(Response.first.id.to_s)
    %w(Dog Animal Cat).each{ |o| expect(page).to have_selector('div.option-name', text: o) }

    # Delete.
    click_link('Delete Response')
    page.driver.browser.switch_to.alert.accept
    expect(page).to have_selector('.alert-success', text: 'deleted')
  end
end
