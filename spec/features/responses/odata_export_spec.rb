# frozen_string_literal: true

require "rails_helper"

feature "responses odata export", js: true do
  let(:user) { create(:user) }
  let(:params) do
    {
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name
    }
  end

  before { login(user) }

  scenario "exporting odata" do
    visit(responses_path(params))

    click_link("Connect to OData")
    expect(page).to(have_selector(".widget pre", text: /#{OData::BASE_PATH}/))

    find("#copy-btn-api_url").click
    expect(clipboard).to match(/#{OData::BASE_PATH}/)
  end
end
