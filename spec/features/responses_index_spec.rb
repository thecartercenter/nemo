require 'spec_helper'

feature 'responses index' do
  before do
    @user = create(:user)
    @form = create(:form, name: 'TheForm')
  end

  # Need to use selenium here or we don't get the issue with missing AJAX-loaded response.
  scenario 'returning to index after response loaded via ajax', js: true, driver: :selenium do
    login(@user)
    click_link('Responses')
    expect(page).not_to have_content('TheForm')

    # Create response and make it show up via AJAX
    create(:response, form: @form)
    page.execute_script('responses_fetch();')
    expect(page).to have_content('TheForm')

    # Click response and then go back. Should still be there!
    click_link(Response.first.id.to_s)
    page.execute_script('window.history.back()')
    expect(page).to have_content('TheForm')
  end
end
