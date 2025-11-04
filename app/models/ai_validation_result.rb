# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_validation_results
#
#  id                    :uuid             not null, primary key
#  ai_validation_rule_id :uuid             not null
#  response_id           :uuid             not null
#  validation_type       :string(255)      not null
#  confidence_score      :decimal(5,2)     not null
#  is_valid              :boolean          not null
#  issues                :text             default([]), is an Array
#  suggestions           :text             default([]), is an Array
#  explanation           :text
#  passed                :boolean          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_ai_validation_results_on_ai_validation_rule_id  (ai_validation_rule_id)
#  index_ai_validation_results_on_response_id           (response_id)
#  index_ai_validation_results_on_validation_type       (validation_type)
#  index_ai_validation_results_on_passed                (passed)
#

class AiValidationResult < ApplicationRecord
  belongs_to :ai_validation_rule
  belongs_to :response

  validates :validation_type, presence: true
  validates :confidence_score, presence: true, numericality: { in: 0.0..1.0 }
  validates :is_valid, inclusion: { in: [true, false] }
  validates :passed, inclusion: { in: [true, false] }

  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :by_type, ->(type) { where(validation_type: type) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.8) }
  scope :low_confidence, -> { where('confidence_score < ?', 0.5) }

  def severity
    return 'low' if confidence_score < 0.5
    return 'medium' if confidence_score < 0.8
    'high'
  end

  def status
    return 'passed' if passed?
    return 'warning' if confidence_score >= 0.5
    'failed'
  end

  def formatted_issues
    issues.map { |issue| "• #{issue}" }.join("\n")
  end

  def formatted_suggestions
    suggestions.map { |suggestion| "• #{suggestion}" }.join("\n")
  end

  def summary
    {
      rule_name: ai_validation_rule.name,
      validation_type: validation_type,
      status: status,
      severity: severity,
      confidence: (confidence_score * 100).round(1),
      issues_count: issues.length,
      suggestions_count: suggestions.length,
      explanation: explanation
    }
  end
end