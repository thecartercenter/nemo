# frozen_string_literal: true

require "rails_helper"

feature "option set import", js: true do
  include_context "file import"

  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  around do |example|
    # A strange error was happening due to the transaction inside OptionSetImport.
    # To see it, comment this ENV variable and watch the test log DB queries.
    # Since this is a happy path we can turn it off just for this spec.
    ENV["NO_TRANSACTION_IN_IMPORT"] = "1"
    example.run
    ENV.delete("NO_TRANSACTION_IN_IMPORT")
  end

  before do
    login(admin)
  end

  scenario "happy path" do
    visit("/en/m/#{mission.compact_name}/option-set-imports/new")
    try_invalid_uploads_and_then(option_set_import_fixture("simple.csv").path) do
      fill_in("Option Set Name", with: "New Opt Set")
    end
    expect(page).to have_content("Option Set import queued")
    Delayed::Worker.new.work_off
    click_link("operations panel")
    click_on("Option Set 'simple.csv' import")
    expect(page).to have_content("Status\nSuccess")
  end
end
