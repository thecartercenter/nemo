# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :option_node do
    ancestry "MyString"
    option_set_id 1
    rank 1
    option_id 1
  end
end
