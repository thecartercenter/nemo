# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: broadcasts
#
#  id                  :uuid             not null, primary key
#  body                :text             not null
#  medium              :string(255)      not null
#  recipient_selection :string(255)      not null
#  send_errors         :text
#  sent_at             :datetime
#  source              :string(255)      default("manual"), not null
#  subject             :string(255)
#  which_phone         :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  mission_id          :uuid             not null
#
# Indexes
#
#  index_broadcasts_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  broadcasts_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :broadcast do
    mission { get_mission }
    medium { "email" }
    recipient_selection { "specific" }
    subject { "test broadcast" }
    which_phone { "main_only" }
    body { "This is the Body of a Broadcast" }

    trait :with_recipient_users do
      recipients { [create(:user), create(:user)] }
    end
  end
end
