# frozen_string_literal: true

require "rails_helper"

feature "sms index", js: true do
  include_context "search"

  let(:user) { create(:user) }
  let!(:smses) do
    [
      create(:sms_incoming, body: "alpha bravo charlie", sent_at: Time.current - 70.seconds),
      create(:sms_reply, body: "delta charlie foxtrot", reply_error_message: "foo"),
      create(:sms_broadcast, body: "golf hotel india")
    ]
  end

  before do
    login(user)
  end

  scenario "general content" do
    visit(sms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_content("When sending reply: foo")
    expect(page).to have_content("(sent 1m earlier)")
    smses.each { |sms| expect(page).to have_content(sms.body) }
  end

  scenario "search" do
    visit(sms_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
    expect(page).to have_content(/Displaying all \d+ SMSes/)
    expect(page).to have_content(smses[0].body)
    expect(page).to have_content(smses[1].body)
    expect(page).to have_content(smses[2].body)

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
    expect(page).to have_content(/Displaying all \d+ SMSes/)

    # Search error.
    search_for("fail:")
    expect(page).to have_content("Error: Your search query could not be understood "\
      "due to unexpected text near the end.")
  end
end
