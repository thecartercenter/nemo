require "rails_helper"

feature "user batch file upload", js: true do
  include_context "dropzone"

  let(:mission){ create(:mission) }
  let(:admin) { create(:user, role_name: "coordinator", admin: true) }
  let(:user_batch) { Rails.root.join("spec", "fixtures", "user_batches", "batch_of_3.csv") }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(admin) }
  scenario "uploading file" do
    visit new_user_batch_path(params)
    user_batch_node = find(".user_batch_form")

    # try hitting submit with no file, expect error
    click_button("Import")
    expect(page).to have_content("No file selected for import.")

    # try uploading valid file
    drop_in_dropzone(user_batch, 0)
    expect_preview(user_batch_node)
    expect(page).to have_content("batch_of_3.csv")
  end
end
