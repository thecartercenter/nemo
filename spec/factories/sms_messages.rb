# frozen_string_literal: true

FactoryGirl.define do
  factory :sms_message, class: "Sms::Message" do
    to { "+1709#{rand(1_000_000..9_999_999)}" }
    from { "+1709#{rand(1_000_000..9_999_999)}" }
    body { Faker::Lorem.sentence }
    sent_at { Time.current }
    mission { get_mission }
  end

  factory :sms_incoming, class: "Sms::Incoming", parent: :sms_message do
  end

  factory :sms_reply, class: "Sms::Reply", parent: :sms_message do
  end

  factory :sms_broadcast, class: "Sms::Broadcast", parent: :sms_message do
    broadcast
  end
end
