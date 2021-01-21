# frozen_string_literal: true

require "rails_helper"

feature "user import", js: true do
  include_context "file import"

  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  scenario "happy path" do
    visit("/en/m/#{mission.compact_name}/user-imports/new")
    try_invalid_uploads_and_then(user_import_fixture("varying_info.csv").path)
    expect(page).to have_content("User import queued")
    Delayed::Worker.new.work_off
    click_link("operations panel")
    click_on("User import from varying_info.csv")
    expect(page).to have_content("Status\nSuccess")
  end
end
