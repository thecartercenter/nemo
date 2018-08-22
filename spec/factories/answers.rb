# frozen_string_literal: true

FactoryGirl.define do
  factory :answer do
    value 1
    association :form_item, factory: :questioning
  end
end
