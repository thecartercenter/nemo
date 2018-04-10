FactoryGirl.define do
  factory :answer do
    value 1
    association(:questioning)
  end
end
