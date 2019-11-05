# frozen_string_literal: true

require "rails_helper"

feature "SMS Console", js: true do
  let!(:user) { create(:user) }
  let!(:mission_name) { get_mission.compact_name }
  let(:form) { create(:form, :live, question_types: %w[integer], smsable: true) }

  before do
    login(user)
  end

  scenario "testing SMS console" do
    visit(new_sms_test_path(mode: "m", mission_name: mission_name, locale: "en"))
    fill_in("From", with: user.phone)
    fill_in("Body", with: "#{form.code} 1.123")
    click_button("Send")

    expect(page).to have_content("Your response to form")
    expect(page).to have_button("Send", disabled: false)
  end
end
