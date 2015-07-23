FactoryGirl.define do
  factory :broadcast do
    medium "email"
    subject "test broadcast"
    which_phone "main_only"
    body "This is the Body of a Broadcast"
  end
end
