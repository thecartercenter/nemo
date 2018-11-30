# frozen_string_literal: true

require "rails_helper"

feature "user batch file upload", js: true do
  include_context "file import"

  let(:mission) { create(:mission) }
  let(:admin) { create(:user, role_name: "coordinator", admin: true) }
  let(:user_import) { Rails.root.join("spec", "fixtures", "user_imports", "batch_of_3.csv") }
  let(:option_set_import) { Rails.root.join("spec", "fixtures", "option_set_imports", "simple.csv") }
  let(:invalid_file) { Rails.root.join("spec", "fixtures", "media", "images", "the_swing.jpg") }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(admin) }

  scenario "uploading user batch" do
    visit new_user_import_path(params)
    node = find(".user_import_form")
    run_scenario(node, user_import, "batch_of_3.csv")
  end

  scenario "uploading option set import" do
    visit new_option_set_imports_path(params)
    node = find(".option_set_import_form")
    run_scenario(node, option_set_import, "simple.csv")
  end


end
