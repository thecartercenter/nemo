# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
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
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :media_object, class: "Media::Object" do
    item { media_fixture("images/the_swing.jpg") }

    factory :media_image, class: "Media::Image" do
      jpg

      trait :jpg do
        item { media_fixture("images/the_swing.jpg") }
      end
      trait :png do
        item { media_fixture("images/the_swing.png") }
      end
      trait :tiff do
        item { media_fixture("images/the_swing.tiff") }
      end
    end

    factory :media_audio, class: "Media::Audio" do
      m4a

      trait :flac do
        item { media_fixture("audio/powerup.flac") }
      end

      trait :m4a do
        item { media_fixture("audio/powerup.m4a") }
      end

      trait :mp3 do
        item { media_fixture("audio/powerup.mp3") }
      end

      trait :ogg do
        item { media_fixture("audio/powerup.ogg") }
      end

      trait :opus do
        item { media_fixture("audio/powerup.opus") }
      end

      trait :wav do
        item { media_fixture("audio/powerup.wav") }
      end

      trait :webm do
        item { media_fixture("audio/powerup.webm") }
      end
    end

    factory :media_video, class: "Media::Video" do
      mp4

      trait :'3gp' do
        item { media_fixture("video/jupiter.3gp") }
      end

      trait :avi do
        item { media_fixture("video/jupiter.avi") }
      end

      trait :mp4 do
        item { media_fixture("video/jupiter.mp4") }
      end

      trait :mpeg do
        item { media_fixture("video/jupiter.mpeg") }
      end

      trait :webm do
        item { media_fixture("video/jupiter.webm") }
      end

      trait :wmv do
        item { media_fixture("video/jupiter.wmv") }
      end

      trait :ogv do
        item { media_fixture("video/jupiter.ogv") }
      end
    end
  end
end
