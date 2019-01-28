require 'rails_helper'

feature 'switching between missions and modes', js: true do
  before do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
    @user = create(:user)
    @form = create(:form, mission: @mission1)
    @user.assignments.create!(mission: @mission2, role: 'coordinator')
    login(@user)
  end

  scenario 'should work' do
    # We get logged in to mission2, so first test that changing to mission1 from mission2 root works.
    expect(current_url).to match("/m/#{@mission2.compact_name}")
    select(@mission1.name, from: 'change-mission')
    expect(page).to have_selector('#title h2', text: /#{@mission1.name}/i)

    # Smart redirect on mission change should work.
    # (Note this the controller logic for this is extensively tested in mission_change_redirect_spec but this test
    # ensures that the missionchange parameter is getting set by JS, etc.)
    click_link('Forms')
    click_link(@form.name)
    expect(page).to have_selector('h1.title', text: @form.name)
    select(@mission2.name, from: 'change-mission')
    expect(page).to have_selector('h1.title', text: 'Forms')

    # Changing mission from unauthorized page should work.
    visit('/en/unauthorized')
    select(@mission1.name, from: 'change-mission')
    sleep 2 # Test fails without this, even though have_selector is supposed to wait.
    expect(page).to have_selector('#title h2', text: /#{@mission1.name}/i)
  end
end
