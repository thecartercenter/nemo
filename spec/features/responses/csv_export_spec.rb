# frozen_string_literal: true

require "rails_helper"

feature "responses csv export" do
  include ActiveJob::TestHelper

  let(:form) { create(:form, :live, question_types: %w[integer multilevel_select_one]) }
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

  scenario "exporting csv happy path" do
    visit(responses_path(params))

    click_link("Download CSV")
    # This expectation doesn't work unless :js is enabled (in which case we can't download the resulting CSV).
    # expect(page).to(have_content("#{Response.all.length} responses to be exported"))

    perform_enqueued_jobs do
      click_button("Export")
    end

    expect(page).to(have_content("Response CSV export queued"))
    click_link("operations panel")
    expect(page).to(have_content("Response CSV export"))
    expect(page).to(have_content("Success"))

    click_link("Response CSV export")
    click_link("Download CSV")

    result = CSV.parse(page.body)
    expect(result.size).to(eq(3)) # 2 response rows, 1 header row
    expect(result[1][9]).to(eq("Animal"))
    expect(result[2][9]).to(eq("Plant"))
  end

  scenario "exporting csv with nothing checked", :js do
    visit(responses_path(params))

    click_link("Download CSV")
    expect(page).to(have_content("#{Response.all.length} responses to be exported"))
  end

  scenario "exporting csv with checkbox selection", :js do
    visit(responses_path(params))

    check("selected[#{response1.id}]")

    click_link("Download CSV")
    expect(page).to(have_content("1 response to be exported"))
  end

  context "with multiple pages" do
    before do
      stub_const("ResponsesController::PER_PAGE", 1)
    end

    scenario "exporting csv with checkbox selection AND 'select all' override", :js do
      visit(responses_path(params))

      check("selected[#{response2.id}]")
      click_link("Select all #{Response.all.length} Responses")

      click_link("Download CSV")
      expect(page).to(have_content("#{Response.all.length} responses to be exported"))
    end
  end

  scenario "export with threshold warning" do
    stub_const("ResponsesController::CSV_EXPORT_WARNING", 1)
    visit(responses_path(params))
    click_link("Download CSV")
    expect(page).to(have_content("may take a long time"))
  end

  scenario "export with threshold limit" do
    stub_const("ResponsesController::CSV_EXPORT_LIMIT", 1)
    visit(responses_path(params))
    click_link("Download CSV")
    expect(page).to(have_content("is not permitted"))
  end

  describe "bulk media download", js: true do
    scenario "without a threshold" do
      visit(responses_path(params))
      click_link("Download CSV")
      check("response_csv_export_options[download_media]")
      expect(page).to(have_content("Total size of media: 0 MB"))
      expect(page).to(have_button("Export", disabled: false))
    end

    context "No space on disk for bulk media export" do
      before do
        stub = double(block_size: 0, blocks_available: 0)
        allow(Sys::Filesystem).to receive(:stat).and_return(stub)
      end

      scenario "Should see an error" do
        visit(responses_path(params))
        click_link("Download CSV")
        check("response_csv_export_options[download_media]")
        expect(page).to(have_content("There is not enough space"))
        expect(page).to(have_button("Export", disabled: true))
        uncheck("response_csv_export_options[download_media]")
        expect(page).to(have_button("Export", disabled: false))
      end
    end
  end

  scenario "exporting csv with bulk media download" do
    visit(responses_path(params))
    click_link("Download CSV")
    expect(page).to(have_content("#{Response.all.length} responses to be exported"))

    perform_enqueued_jobs do
      check("response_csv_export_options[download_media]")
      click_button("Export")
    end

    expect(page).to(have_content("Response CSV export queued"))
    click_link("operations panel")
    expect(page).to(have_content("Bulk Media export"))
    expect(page).to(have_content("Response CSV export"))
    expect(page).to(have_content("Success"))
  end
end
