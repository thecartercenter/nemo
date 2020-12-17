# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: media_objects
#
#  id                :uuid             not null, primary key
#  item_content_type :string(255)      not null
#  item_file_name    :string(255)      not null
#  item_file_size    :integer          not null
#  item_updated_at   :datetime         not null
#  type              :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  answer_id         :uuid
#
# Indexes
#
#  index_media_objects_on_answer_id  (answer_id)
#
# Foreign Keys
#
#  media_objects_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :media_object, class: "Media::Object" do
    # This is attached after build.
    item { nil }

    transient do
      file { media_fixture("images/the_swing.jpg") }
    end

    after(:build) do |obj, evaluator|
      obj.item.attach(io: evaluator.file, filename: File.basename(evaluator.file))
    end

    factory :media_image, class: "Media::Image" do
      jpg

      trait :jpg do
        file { media_fixture("images/the_swing.jpg") }
      end

      trait :png do
        file { media_fixture("images/the_swing.png") }
      end

      trait :tiff do
        file { media_fixture("images/the_swing.tiff") }
      end
    end

    factory :media_audio, class: "Media::Audio" do
      m4a

      trait :flac do
        file { media_fixture("audio/powerup.flac") }
      end

      trait :m4a do
        file { media_fixture("audio/powerup.m4a") }
      end

      trait :mp3 do
        file { media_fixture("audio/powerup.mp3") }
      end

      trait :ogg do
        file { media_fixture("audio/powerup.ogg") }
      end

      trait :opus do
        file { media_fixture("audio/powerup.opus") }
      end

      trait :wav do
        file { media_fixture("audio/powerup.wav") }
      end

      trait :webm do
        file { media_fixture("audio/powerup.webm") }
      end
    end

    factory :media_video, class: "Media::Video" do
      mp4

      trait :'3gp' do
        file { media_fixture("video/jupiter.3gp") }
      end

      trait :avi do
        file { media_fixture("video/jupiter.avi") }
      end

      trait :mp4 do
        file { media_fixture("video/jupiter.mp4") }
      end

      trait :mpeg do
        file { media_fixture("video/jupiter.mpeg") }
      end

      trait :webm do
        file { media_fixture("video/jupiter.webm") }
      end

      trait :wmv do
        file { media_fixture("video/jupiter.wmv") }
      end

      trait :ogv do
        file { media_fixture("video/jupiter.ogv") }
      end
    end
  end
end
