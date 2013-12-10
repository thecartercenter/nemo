FactoryGirl.define do
  factory :broadcast do
    recipients {|r| [r.association(:user)]} #association :recipients, :factory => :user
    medium "email"
    subject "test broadcast"
    which_phone "main_only"
    body "This is the Body of a Broadcast"

  end
end
