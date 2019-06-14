# frozen_string_literal: true

require "rails_helper"

feature "sms message search", js: true do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:user) { create(:user, role_name: "coordinator", admin: true) }
  let!(:smses) do
    [
      create(:sms_incoming, body: "alpha bravo charlie", sent_at: Time.current - 70.seconds),
      create(:sms_reply, body: "delta charlie foxtrot", reply_error_message: "foo"),
      create(:sms_broadcast, body: "golf hotel india")
    ]
  end

  scenario "search" do
    login(user)
    visit "/en/m/#{mission.compact_name}/sms"
    expect(page).to have_content("Displaying all 3 SMSes")
    expect(page).to have_content(smses[0].body)

    # Working search.
    search_for("charlie")
    expect(page).to have_content(smses[0].body)
    expect(page).to have_content(smses[1].body)
    expect(page).not_to have_content(smses[2].body)

    # Failing search.
    search_for("bobby fisher")
    expect(page).to have_content("No SMSes found")

    # Empty search.
    search_for("")
    expect(page).to have_content("Displaying all 3 SMSes")

    # Search error.
    search_for("creepy:")
    expect(page).to have_content(
      "Error: Your search query could not be understood due to unexpected text near the end."
    )
  end
end
