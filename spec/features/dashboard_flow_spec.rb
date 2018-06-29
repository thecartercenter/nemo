require 'rails_helper'

feature 'dashboard flow', js: true do
  before do
    @user = create(:user)
    login(@user)
    visit(mission_root_path(mission_name: get_mission.compact_name, locale: 'en'))
  end

  scenario 'should work' do
    click_link('Reload via AJAX')
    wait_for_ajax
    expect(page).to have_content('LATEST RESPONSES')
  end
end
