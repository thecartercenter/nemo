# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :option_level do
    option_set_id 1
    rank 1
    name_translations "MyText"
    mission_id 1
    is_standard false
    standard_id 1
  end
end
