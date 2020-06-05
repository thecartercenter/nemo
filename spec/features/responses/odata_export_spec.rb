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

    click_link("Export")
    click_link("OData via API")
    expect(page).to(have_selector(".widget pre", text: %r{/odata/v1}))
  end
end
