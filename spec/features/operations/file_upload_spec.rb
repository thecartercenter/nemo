require "rails_helper"

feature "user batch file upload", js: true do
  include_context "dropzone"

  let(:mission){ create(:mission) }
  let(:admin) { create(:user, role_name: "coordinator", admin: true) }
  let(:user_batch) { Rails.root.join("spec", "fixtures", "user_batches", "batch_of_3.csv") }
  let(:invalid_file) { Rails.root.join("spec", "fixtures", "media", "images", "the_swing.jpg") }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(admin) }
  scenario "uploading file" do
    visit new_user_batch_path(params)
    user_batch_node = find(".user_batch_form")

    # try hitting submit with no file, expect error
    click_button("Import")
    expect(page).to have_content("No file selected for import.")

    # invalid file
    drop_in_dropzone(invalid_file, 0)
    expect_no_preview(user_batch_node)
    expect(page).to have_content("The uploaded file was not an accepted format.")
    expect(page).to have_button("Import")

    # try uploading valid file
    drop_in_dropzone(user_batch, 0)
    expect_preview(user_batch_node)
    expect(page).to have_content("batch_of_3.csv")
  end
end
