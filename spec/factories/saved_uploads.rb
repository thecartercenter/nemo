# frozen_string_literal: true

FactoryGirl.define do
  factory :saved_upload, class: SavedTabularUpload do
    transient { filename nil }
    file { user_import_fixture(filename) }
  end
end
