# frozen_string_literal: true

# == Schema Information
#
# Table name: validation_rules
#
#  id          :uuid             not null, primary key
#  name        :string(255)      not null
#  description :text
#  rule_type   :string(255)      not null
#  conditions  :jsonb
#  message     :string(255)
#  is_active   :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  form_id     :uuid
#  question_id :uuid
#  mission_id  :uuid             not null
#
# Indexes
#
#  index_validation_rules_on_form_id     (form_id)
#  index_validation_rules_on_mission_id  (mission_id)
#  index_validation_rules_on_question_id (question_id)
#  index_validation_rules_on_rule_type   (rule_type)
#  index_validation_rules_on_is_active   (is_active)
#
# Foreign Keys
#
#  validation_rules_form_id_fkey     (form_id => forms.id) ON DELETE => cascade
#  validation_rules_mission_id_fkey  (mission_id => missions.id) ON DELETE => cascade
#  validation_rules_question_id_fkey (question_id => questions.id) ON DELETE => cascade
#

class ValidationRule < ApplicationRecord
  include MissionBased

  belongs_to :form, optional: true
  belongs_to :question, optional: true
  belongs_to :mission

  validates :name, presence: true
  validates :rule_type, presence: true
  validates :conditions, presence: true

  scope :active, -> { where(is_active: true) }
  scope :for_form, ->(form) { where(form: form) }
  scope :for_question, ->(question) { where(question: question) }
  scope :global, -> { where(form_id: nil, question_id: nil) }

  RULE_TYPES = %w[
    required
    min_length
    max_length
    min_value
    max_value
    pattern
    custom
    cross_field
    conditional
  ].freeze

  validates :rule_type, inclusion: {in: RULE_TYPES}

  def self.validate_response(response)
    errors = []

    # Get all applicable validation rules
    rules = ValidationRule.active
      .where(mission: response.mission)
      .where("form_id IS NULL OR form_id = ?", response.form_id)

    rules.each do |rule|
      rule_errors = rule.validate_response(response)
      errors.concat(rule_errors) if rule_errors.any?
    end

    errors
  end

  def validate_response(response)
    return [] unless applicable_to_response?(response)

    case rule_type
    when "required"
      validate_required(response)
    when "min_length"
      validate_min_length(response)
    when "max_length"
      validate_max_length(response)
    when "min_value"
      validate_min_value(response)
    when "max_value"
      validate_max_value(response)
    when "pattern"
      validate_pattern(response)
    when "custom"
      validate_custom(response)
    when "cross_field"
      validate_cross_field(response)
    when "conditional"
      validate_conditional(response)
    else
      []
    end
  end

  def applicable_to_response?(response)
    return false unless is_active?
    return false unless response.mission == mission

    return false if form_id.present? && !(response.form_id == form_id)

    if question_id.present? && !response.answers.joins(:questioning).where(questionings: {question_id: question_id}).exists?
      return false
    end

    true
  end

  private

  def validate_required(response)
    errors = []

    if question_id.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.blank? || answer.value.blank?
        errors << {
          question_id: question_id,
          message: message || "This field is required",
          rule_id: id
        }
      end
    end

    errors
  end

  def validate_min_length(response)
    errors = []
    min_length = conditions["min_length"].to_i

    if question_id.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.present? && answer.value.present? && answer.value.length < min_length
        errors << {
          question_id: question_id,
          message: message || "Must be at least #{min_length} characters long",
          rule_id: id
        }
      end
    end

    errors
  end

  def validate_max_length(response)
    errors = []
    max_length = conditions["max_length"].to_i

    if question_id.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.present? && answer.value.present? && answer.value.length > max_length
        errors << {
          question_id: question_id,
          message: message || "Must be no more than #{max_length} characters long",
          rule_id: id
        }
      end
    end

    errors
  end

  def validate_min_value(response)
    errors = []
    min_value = conditions["min_value"].to_f

    if question_id.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.present? && answer.value.present?
        value = answer.value.to_f
        if value < min_value
          errors << {
            question_id: question_id,
            message: message || "Must be at least #{min_value}",
            rule_id: id
          }
        end
      end
    end

    errors
  end

  def validate_max_value(response)
    errors = []
    max_value = conditions["max_value"].to_f

    if question_id.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.present? && answer.value.present?
        value = answer.value.to_f
        if value > max_value
          errors << {
            question_id: question_id,
            message: message || "Must be no more than #{max_value}",
            rule_id: id
          }
        end
      end
    end

    errors
  end

  def validate_pattern(response)
    errors = []
    pattern = conditions["pattern"]

    if question_id.present? && pattern.present?
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: question_id})
      if answer.present? && answer.value.present?
        regex = Regexp.new(pattern)
        unless regex.match?(answer.value)
          errors << {
            question_id: question_id,
            message: message || "Format is invalid",
            rule_id: id
          }
        end
      end
    end

    errors
  end

  def validate_custom(response)
    errors = []

    # Custom validation logic would be implemented here
    # This could involve calling external services or complex business logic
    if conditions["custom_logic"].present?
      begin
        # In a real implementation, this would be more sophisticated
        # For now, we'll just check if the custom logic returns false
        result = evaluate_custom_logic(conditions["custom_logic"], response)
        unless result
          errors << {
            question_id: question_id,
            message: message || "Custom validation failed",
            rule_id: id
          }
        end
      rescue StandardError => e
        errors << {
          question_id: question_id,
          message: "Validation error: #{e.message}",
          rule_id: id
        }
      end
    end

    errors
  end

  def validate_cross_field(response)
    errors = []

    # Cross-field validation logic
    if conditions["field_1"].present? && conditions["field_2"].present?
      field1_value = get_field_value(response, conditions["field_1"])
      field2_value = get_field_value(response, conditions["field_2"])
      operator = conditions["operator"] || "=="

      unless evaluate_cross_field_condition(field1_value, field2_value, operator)
        errors << {
          question_id: question_id,
          message: message || "Cross-field validation failed",
          rule_id: id
        }
      end
    end

    errors
  end

  def validate_conditional(response)
    errors = []

    # Conditional validation based on other field values
    if conditions["condition_field"].present? && conditions["condition_value"].present?
      condition_field_value = get_field_value(response, conditions["condition_field"])
      condition_value = conditions["condition_value"]
      condition_operator = conditions["condition_operator"] || "=="

      if evaluate_condition(condition_field_value, condition_value, condition_operator)
        # Apply the validation rule
        case conditions["validation_type"]
        when "required"
          errors.concat(validate_required(response))
        when "min_length"
          errors.concat(validate_min_length(response))
        when "max_length"
          errors.concat(validate_max_length(response))
        when "min_value"
          errors.concat(validate_min_value(response))
        when "max_value"
          errors.concat(validate_max_value(response))
        when "pattern"
          errors.concat(validate_pattern(response))
        end
      end
    end

    errors
  end

  def get_field_value(response, field_identifier)
    # This would need to be implemented based on how fields are identified
    # Could be by question code, question ID, or other identifier
    if field_identifier.is_a?(String) && field_identifier.match?(/^\d+$/)
      # Assume it's a question ID
      answer = response.answers.joins(:questioning).find_by(questionings: {question_id: field_identifier})
      answer&.value
    else
      # Assume it's a question code
      answer = response.answers.joins(:questioning).joins(:question)
        .find_by(questions: {code: field_identifier})
      answer&.value
    end
  end

  def evaluate_cross_field_condition(value1, value2, operator)
    case operator
    when "=="
      value1 == value2
    when "!="
      value1 != value2
    when ">"
      value1.to_f > value2.to_f
    when "<"
      value1.to_f < value2.to_f
    when ">="
      value1.to_f >= value2.to_f
    when "<="
      value1.to_f <= value2.to_f
    else
      false
    end
  end

  def evaluate_condition(field_value, expected_value, operator)
    evaluate_cross_field_condition(field_value, expected_value, operator)
  end

  def evaluate_custom_logic(logic, response)
    # This is a simplified example
    # In a real implementation, this would be much more sophisticated
    # and would likely use a safe evaluation mechanism
    case logic
    when "email_format"
      response.answers.joins(:questioning).joins(:question)
        .where(questions: {code: "email"})
        .first&.value&.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    when "phone_format"
      response.answers.joins(:questioning).joins(:question)
        .where(questions: {code: "phone"})
        .first&.value&.match?(/\A\+?[\d\s\-\(\)]+\z/)
    else
      true
    end
  end
end
