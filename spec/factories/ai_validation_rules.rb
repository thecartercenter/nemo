# frozen_string_literal: true

FactoryBot.define do
  factory :ai_validation_rule do
    transient do
      mission { get_mission }
      user { create(:user, mission: mission) }
    end

    name { "Test Validation Rule" }
    description { "Test description" }
    rule_type { "data_quality" }
    ai_model { "gpt-3.5-turbo" }
    threshold { 0.8 }
    active { true }
    config { {} }

    association :mission, factory: :mission
    association :user, factory: :user

    trait :inactive do
      active { false }
    end

    trait :anomaly_detection do
      rule_type { "anomaly_detection" }
      name { "Anomaly Detection Rule" }
    end

    trait :consistency_check do
      rule_type { "consistency_check" }
      name { "Consistency Check Rule" }
    end

    trait :completeness_check do
      rule_type { "completeness_check" }
      name { "Completeness Check Rule" }
    end

    trait :format_validation do
      rule_type { "format_validation" }
      name { "Format Validation Rule" }
    end

    trait :business_logic do
      rule_type { "business_logic" }
      name { "Business Logic Rule" }
      config { {business_rules: "Age must be between 18 and 100"} }
    end

    trait :duplicate_detection do
      rule_type { "duplicate_detection" }
      name { "Duplicate Detection Rule" }
    end

    trait :outlier_detection do
      rule_type { "outlier_detection" }
      name { "Outlier Detection Rule" }
    end

    trait :low_threshold do
      threshold { 0.5 }
    end

    trait :high_threshold do
      threshold { 0.9 }
    end
  end
end
