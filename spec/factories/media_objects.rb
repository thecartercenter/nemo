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
    # Attached after build.
    item { nil }

    transient do
      filename { "images/the_swing.jpg" }
      fixture { media_fixture(filename) }
    end

    after(:build) do |obj, evaluator|
      obj.item.attach(io: evaluator.fixture, filename: File.basename(evaluator.fixture))
    end

    factory :media_image, class: "Media::Image" do
      jpg

      trait :jpg do
        filename { "images/the_swing.jpg" }
      end

      trait :png do
        filename { "images/the_swing.png" }
      end

      trait :tiff do
        filename { "images/the_swing.tiff" }
      end
    end

    factory :media_audio, class: "Media::Audio" do
      m4a

      trait :flac do
        filename { "audio/powerup.flac" }
      end

      trait :m4a do
        filename { "audio/powerup.m4a" }
      end

      trait :mp3 do
        filename { "audio/powerup.mp3" }
      end

      trait :ogg do
        filename { "audio/powerup.ogg" }
      end

      trait :opus do
        filename { "audio/powerup.opus" }
      end

      trait :wav do
        filename { "audio/powerup.wav" }
      end

      trait :webm do
        filename { "audio/powerup.webm" }
      end
    end

    factory :media_video, class: "Media::Video" do
      mp4

      trait :'3gp' do
        filename { "video/jupiter.3gp" }
      end

      trait :avi do
        filename { "video/jupiter.avi" }
      end

      trait :mp4 do
        filename { "video/jupiter.mp4" }
      end

      trait :mpeg do
        filename { "video/jupiter.mpeg" }
      end

      trait :webm do
        filename { "video/jupiter.webm" }
      end

      trait :wmv do
        filename { "video/jupiter.wmv" }
      end

      trait :ogv do
        filename { "video/jupiter.ogv" }
      end
    end
  end
end
