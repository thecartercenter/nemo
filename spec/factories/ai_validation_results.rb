# frozen_string_literal: true

FactoryBot.define do
  factory :ai_validation_result do
    transient do
      mission { get_mission }
      form { create(:form, mission: mission) }
      response { create(:response, form: form, mission: mission) }
      rule { create(:ai_validation_rule, mission: mission) }
    end

    association :ai_validation_rule, factory: :ai_validation_rule
    association :response, factory: :response

    validation_type { "data_quality" }
    confidence_score { 0.85 }
    is_valid { true }
    passed { true }
    issues { [] }
    suggestions { [] }
    explanation { "Validation completed successfully" }

    trait :failed do
      passed { false }
      is_valid { false }
      confidence_score { 0.6 }
      issues { ["Data quality issue detected", "Missing required field"] }
      suggestions { ["Please review the data", "Add missing information"] }
      explanation { "Validation failed due to data quality issues" }
    end

    trait :low_confidence do
      confidence_score { 0.4 }
      passed { false }
    end

    trait :high_confidence do
      confidence_score { 0.95 }
      passed { true }
    end

    trait :with_issues do
      issues { ["Issue 1", "Issue 2"] }
      suggestions { ["Suggestion 1", "Suggestion 2"] }
    end

    trait :anomaly_detection do
      validation_type { "anomaly_detection" }
    end

    trait :consistency_check do
      validation_type { "consistency_check" }
    end
  end
end
