# frozen_string_literal: true

FactoryGirl.define do
  factory :sms_message, class: "Sms::Message" do
    to "+123456789"
    from "+234567890"
    body "MyText"
    sent_at "2013-04-30 08:52:03"
    mission { get_mission }
  end

  factory :sms_incoming, class: "Sms::Incoming", parent: :sms_message do
  end

  factory :sms_reply, class: "Sms::Reply", parent: :sms_message do
  end

  factory :sms_broadcast, class: "Sms::Broadcast", parent: :sms_message do
  end
end
