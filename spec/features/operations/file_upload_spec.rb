require "rails_helper"

feature "user batch file upload", js: true do
  include_context "dropzone"

  let(:mission){ create(:mission) }
  let(:admin) { create(:user, role_name: "coordinator", admin: true) }
  let(:user_batch) { Rails.root.join("spec", "fixtures", "user_batches", "batch_of_3.csv") }
  let(:option_set_import) { Rails.root.join("spec", "fixtures", "option_set_imports", "simple.csv") }
  let(:invalid_file) { Rails.root.join("spec", "fixtures", "media", "images", "the_swing.jpg") }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(admin) }

  scenario "uploading user batch" do
    visit new_user_batch_path(params)
    node = find(".user_batch_form")
    run_scenario(node, user_batch, "batch_of_3.csv")
  end

  scenario "uploading option set import" do
    visit new_option_set_imports_path(params)
    node = find(".option_set_import_form")
    run_scenario(node, option_set_import, "simple.csv")
  end

  def run_scenario(node, correct_file, correct_file_name)
    # try hitting submit with no file, expect error
    click_button("Import")
    expect(page).to have_content("No file selected for import.")

    # invalid file
    drop_in_dropzone(invalid_file, 0)
    expect_no_preview(node)
    expect(page).to have_content("The uploaded file was not an accepted format.")
    expect(page).to have_button("Import")

    # try uploading valid file
    drop_in_dropzone(correct_file, 0)
    expect_preview(node)
    expect(page).to have_content(correct_file_name)
  end
end
