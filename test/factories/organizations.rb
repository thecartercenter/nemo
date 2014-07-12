# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    name {"organization#{rand(10000000)}"}
    subdomain  {"sub#{rand(10000000)}"}
  end
end
