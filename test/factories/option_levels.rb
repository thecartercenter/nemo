# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :option_level do
    option_set
    rank 1
    name_translations Hash['en', 'foo']
    mission { get_mission }
  end
end
