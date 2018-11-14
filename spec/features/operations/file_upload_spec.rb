require "rails_helper"

feature "user batch file upload", js: true do
  include_context "dropzone"

  let(:admin) { create(:admin) }
  let(:user_batch) { Rails.root.join("spec", "fixtures", "user_batches", "batch_of_3.csv") }
  let(:invalid_file) { Rails.root.join("spec", "fixtures", "media", "images", "the_swing.jpg") }

  before { login(admin) }
  scenario "uploading file" do
    visit_new_user_batch_path()

    # try hitting submit with no file, expect error

    # try uploading invalid file type
    #drop_in_dropzone(invalid_file, 0)

    # try uploading valid file
    drop_in_dropzone(user_batch, 0)
  end
end
