# frozen_string_literal: true

FactoryGirl.define do
  factory :broadcast do
    mission { get_mission }
    medium "email"
    recipient_selection "specific"
    subject "test broadcast"
    which_phone "main_only"
    body "This is the Body of a Broadcast"

    trait :with_recipient_users do
      recipients { [create(:user), create(:user)] }
    end
  end
end
