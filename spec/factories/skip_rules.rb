FactoryGirl.define do
  factory :skip_rule do
    destination "end"
    skip_if "all_met"
    association :source_item, factory: :questioning
  end
end
