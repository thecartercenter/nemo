# frozen_string_literal: true

require "rails_helper"

feature "responses csv export" do
  include ActiveJob::TestHelper

  let(:form) { create(:form, :published, question_types: %w[integer multilevel_select_one]) }
  let!(:response1) { create(:response, form: form, answer_values: [2, %w[Animal]]) }
  let!(:response2) { create(:response, form: form, answer_values: [15, %w[Plant]]) }
  let(:user) { create(:user) }

  let(:params) do
    {
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name
    }
  end

  before { login(user) }

  scenario "exporting csv" do
    visit(responses_path(params))

    perform_enqueued_jobs do
      click_link("Export to CSV Format")
    end

    expect(page).to(have_content("Response CSV export queued"))
    click_link("operations panel")
    expect(page).to(have_content("Response CSV export"))
    expect(page).to(have_content("Success"))

    click_link("Response CSV export")
    click_link("download")

    result = CSV.parse(page.body)
    expect(result.size).to(eq(3)) # 2 response rows, 1 header row
    expect(result[1][9]).to(eq("Animal"))
    expect(result[2][9]).to(eq("Plant"))
  end
end
