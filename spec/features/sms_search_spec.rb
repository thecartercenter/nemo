require "spec_helper"

feature "sms search" do
  before do
    @mission = get_mission

    @sms1 = create(:sms_incoming, mission: @mission, body: "I didn't expect the Spanish Inquisition.")
    @sms2 = create(:sms_reply, mission: @mission, body: "Nobody expects the Spanish Inquisition!")
    @sms3 = create(:sms_reply, mission: @mission, body: "Our chief element is surprise and fear.")

    @user = create(:user, role_name: 'coordinator', admin: true)
    login(@user)
  end

  scenario 'search' do
    visit sms_path(mission_name: @mission.compact_name, locale: "en")
    expect(page).to have_content(/Displaying all \d+ SMSes/)
    expect(page).to have_content(@sms1.body)
    expect(page).to have_content(@sms2.body)
    expect(page).to have_content(@sms3.body)

    # Working search.
    search_for('spanish')
    expect(page).not_to have_content(@sms3.body)
    expect(page).to have_content(@sms1.body)
    expect(page).to have_content(@sms2.body)

    # Failing search.
    search_for('bobby fisher')
    expect(page).to have_content("No SMSes found")

    # Empty search.
    search_for('')
    expect(page).to have_content(/Displaying all \d+ SMSes/)

    # Search error.
    search_for('creepy:')
    expect(page).to have_content("Error: Your search query could not be understood due to unexpected text near the end.")
  end

  def search_for(query)
    fill_in("search", with: query)
    click_button("Search")
  end
end
