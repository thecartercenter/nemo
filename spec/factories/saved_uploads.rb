# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: saved_uploads
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :saved_upload, class: SavedTabularUpload do
    # Attached after build.
    file { nil }

    transient do
      filename { nil }
      fixture { user_import_fixture(filename) }
    end

    after(:build) do |obj, evaluator|
      obj.file.attach(io: evaluator.fixture, filename: File.basename(evaluator.fixture))
    end
  end
end
