FactoryGirl.define do
  factory :answer do
    value 1
    association(:form_item)
  end
end
