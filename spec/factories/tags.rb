FactoryGirl.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    mission
    is_standard false
  end
end
