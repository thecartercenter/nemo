# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_validation_rules
#
#  id              :uuid             not null, primary key
#  name            :string(255)      not null
#  description     :text
#  rule_type       :string(255)      not null
#  config          :jsonb
#  ai_model        :string(255)      default('gpt-3.5-turbo')
#  threshold       :decimal(5,2)     default(0.8)
#  active          :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mission_id      :uuid
#  user_id         :uuid
#
# Indexes
#
#  index_ai_validation_rules_on_mission_id  (mission_id)
#  index_ai_validation_rules_on_user_id     (user_id)
#  index_ai_validation_rules_on_rule_type   (rule_type)
#

class AiValidationRule < ApplicationRecord
  include MissionBased

  belongs_to :user
  belongs_to :mission
  has_many :ai_validation_results, dependent: :destroy

  validates :name, presence: true, length: {maximum: 255}
  validates :rule_type, presence: true, inclusion: {in: RULE_TYPES}
  validates :threshold, presence: true, numericality: {in: 0.0..1.0}
  validates :ai_model, presence: true

  scope :active, -> { where(active: true) }
  scope :for_rule_type, ->(type) { where(rule_type: type) }

  RULE_TYPES = %w[
    data_quality
    anomaly_detection
    consistency_check
    completeness_check
    format_validation
    business_logic
    duplicate_detection
    outlier_detection
  ].freeze

  AI_MODELS = %w[
    gpt-3.5-turbo
    gpt-4
    claude-3-sonnet
    claude-3-haiku
  ].freeze

  def validate_response(response)
    case rule_type
    when "data_quality"
      validate_data_quality(response)
    when "anomaly_detection"
      validate_anomaly_detection(response)
    when "consistency_check"
      validate_consistency(response)
    when "completeness_check"
      validate_completeness(response)
    when "format_validation"
      validate_format(response)
    when "business_logic"
      validate_business_logic(response)
    when "duplicate_detection"
      validate_duplicate_detection(response)
    when "outlier_detection"
      validate_outlier_detection(response)
    end
  end

  def validate_data_quality(response)
    prompt = build_data_quality_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "data_quality")
  end

  def validate_anomaly_detection(response)
    prompt = build_anomaly_detection_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "anomaly_detection")
  end

  def validate_consistency(response)
    prompt = build_consistency_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "consistency_check")
  end

  def validate_completeness(response)
    prompt = build_completeness_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "completeness_check")
  end

  def validate_format(response)
    prompt = build_format_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "format_validation")
  end

  def validate_business_logic(response)
    prompt = build_business_logic_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "business_logic")
  end

  def validate_duplicate_detection(response)
    prompt = build_duplicate_detection_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "duplicate_detection")
  end

  def validate_outlier_detection(response)
    prompt = build_outlier_detection_prompt(response)
    result = call_ai_model(prompt)

    create_validation_result(response, result, "outlier_detection")
  end

  private

  def call_ai_model(prompt)
    service = ai_service_provider

    if service&.available?
      begin
        service.call_ai_model(prompt, {
          temperature: config&.dig("temperature") || 0.3,
          max_tokens: config&.dig("max_tokens") || 1000
        })
      rescue StandardError => e
        Rails.logger.error("AI service error for rule #{id}: #{e.message}")
        fallback_response(e)
      end
    else
      # Fallback to mock for development/testing when no API key is configured
      Rails.logger.warn("AI service not available for rule #{id}, using mock response")
      mock_response
    end
  end

  def ai_service_provider
    return nil unless ai_model.present?

    # Check for API key in environment or mission settings
    api_key = find_api_key

    case ai_model
    when /^gpt-/
      # Use OpenAI service if available
      if defined?(AiProviders::OpenaiService) && api_key.present?
        AiProviders::OpenaiService.new(api_key: api_key, model: ai_model)
      end
    when /^claude-/
      # Use Anthropic service if available (to be implemented)
      # if defined?(AiProviders::AnthropicService) && api_key.present?
      #   AiProviders::AnthropicService.new(api_key: api_key, model: ai_model)
      # else
      nil
      # end
    end
  end

  def find_api_key
    # Check environment variables first
    if ai_model.start_with?("gpt")
      ENV["OPENAI_API_KEY"] || ENV.fetch("NEMO_OPENAI_API_KEY", nil)
    elsif ai_model.start_with?("claude")
      ENV["ANTHROPIC_API_KEY"] || ENV.fetch("NEMO_ANTHROPIC_API_KEY", nil)
    end
  end

  def mock_response
    {
      confidence: rand(0.5..1.0),
      is_valid: rand > 0.3,
      issues: generate_sample_issues,
      suggestions: generate_sample_suggestions,
      explanation: "AI analysis completed for #{rule_type} (mock response - configure API key for real validation)"
    }
  end

  def fallback_response(error)
    {
      confidence: 0.0,
      is_valid: false,
      issues: ["AI validation error: #{error.message}"],
      suggestions: ["Please check AI service configuration"],
      explanation: "AI validation failed: #{error.class.name}"
    }
  end

  def create_validation_result(response, result, validation_type)
    ai_validation_results.create!(
      response: response,
      validation_type: validation_type,
      confidence_score: result[:confidence],
      is_valid: result[:is_valid],
      issues: result[:issues],
      suggestions: result[:suggestions],
      explanation: result[:explanation],
      passed: result[:confidence] >= threshold
    )
  end

  def build_data_quality_prompt(response)
    <<~PROMPT
      Analyze the following form response for data quality issues:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}
      Submitted by: #{response.user.name}
      Source: #{response.source}

      Answers:
      #{format_answers_for_prompt(response)}

      Please identify any data quality issues such as:
      - Inconsistent formatting
      - Unrealistic values
      - Missing critical information
      - Typos or spelling errors
      - Logical inconsistencies

      Rate the overall data quality from 0-1 and provide specific recommendations.
    PROMPT
  end

  def build_anomaly_detection_prompt(response)
    <<~PROMPT
      Detect anomalies in this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Look for:
      - Unusual patterns compared to similar responses
      - Values that seem out of range
      - Unexpected combinations of answers
      - Temporal anomalies

      Provide a confidence score and explanation for any anomalies found.
    PROMPT
  end

  def build_consistency_prompt(response)
    <<~PROMPT
      Check for consistency issues in this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Look for:
      - Contradictory answers
      - Inconsistent date formats
      - Mismatched categorical values
      - Logical contradictions

      Identify any inconsistencies and suggest corrections.
    PROMPT
  end

  def build_completeness_prompt(response)
    <<~PROMPT
      Assess the completeness of this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Check for:
      - Missing required fields
      - Incomplete answers
      - Partial responses
      - Essential information gaps

      Rate completeness and identify missing elements.
    PROMPT
  end

  def build_format_prompt(response)
    <<~PROMPT
      Validate the format of data in this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Check for:
      - Proper date formats
      - Valid email addresses
      - Correct phone number formats
      - Proper numeric formats
      - Consistent text formatting

      Identify format issues and suggest corrections.
    PROMPT
  end

  def build_business_logic_prompt(response)
    <<~PROMPT
      Validate business logic rules for this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Business Rules:
      #{config['business_rules'] || 'No specific business rules defined'}

      Check if the response follows the business logic and identify violations.
    PROMPT
  end

  def build_duplicate_detection_prompt(response)
    <<~PROMPT
      Check for potential duplicates of this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Look for:
      - Identical or very similar responses
      - Same submitter with similar data
      - Repeated patterns
      - Potential data entry errors

      Identify potential duplicates and their likelihood.
    PROMPT
  end

  def build_outlier_detection_prompt(response)
    <<~PROMPT
      Detect outliers in this form response:

      Form: #{response.form.name}
      Response ID: #{response.shortcode}

      Answers:
      #{format_answers_for_prompt(response)}

      Look for:
      - Values significantly different from the norm
      - Unusual patterns
      - Statistical outliers
      - Extreme values

      Identify outliers and explain why they might be unusual.
    PROMPT
  end

  def format_answers_for_prompt(response)
    response.answers.map do |answer|
      question = answer.questioning.question
      "#{question.code}: #{question.name} = #{answer.value}"
    end.join("\n")
  end

  def generate_sample_issues
    [
      "Inconsistent date format",
      "Missing required field",
      "Unrealistic value detected",
      "Spelling error in text field"
    ].sample(rand(0..2))
  end

  def generate_sample_suggestions
    [
      "Use consistent date format (YYYY-MM-DD)",
      "Please provide the missing information",
      "Verify this value is correct",
      "Check spelling and grammar"
    ].sample(rand(0..2))
  end
end
