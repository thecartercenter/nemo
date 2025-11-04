# frozen_string_literal: true

# Base class for AI provider services
# Subclasses should implement the call_ai_model method
class AiProviders::BaseService
  attr_reader :api_key, :model, :timeout

  def initialize(api_key:, model: 'gpt-3.5-turbo', timeout: 30)
    @api_key = api_key
    @model = model
    @timeout = timeout
  end

  # Main method to call AI model with a prompt
  # Returns a hash with:
  #   - confidence: Float (0.0-1.0)
  #   - is_valid: Boolean
  #   - issues: Array<String>
  #   - suggestions: Array<String>
  #   - explanation: String
  def call_ai_model(prompt, options = {})
    raise NotImplementedError, "Subclasses must implement call_ai_model"
  end

  # Validate API key format (basic check)
  def valid_api_key?
    api_key.present? && api_key.length > 10
  end

  # Estimate cost for API call (in USD)
  def estimate_cost(prompt_tokens, completion_tokens = 0)
    raise NotImplementedError, "Subclasses must implement estimate_cost"
  end

  # Check if service is available
  def available?
    valid_api_key?
  end

  protected

  # Parse AI response into standardized format
  def parse_response(raw_response)
    {
      confidence: extract_confidence(raw_response),
      is_valid: extract_validity(raw_response),
      issues: extract_issues(raw_response),
      suggestions: extract_suggestions(raw_response),
      explanation: extract_explanation(raw_response)
    }
  rescue => e
    Rails.logger.error "Error parsing AI response: #{e.message}"
    default_error_response
  end

  def extract_confidence(response)
    # Try to extract confidence score from response
    # This is provider-specific and should be overridden
    response[:confidence] || 0.5
  end

  def extract_validity(response)
    response[:is_valid] || false
  end

  def extract_issues(response)
    Array(response[:issues] || [])
  end

  def extract_suggestions(response)
    Array(response[:suggestions] || [])
  end

  def extract_explanation(response)
    response[:explanation] || "AI validation completed"
  end

  def default_error_response
    {
      confidence: 0.0,
      is_valid: false,
      issues: ["Error processing AI validation"],
      suggestions: ["Please check the validation rule configuration"],
      explanation: "An error occurred during AI validation"
    }
  end

end

# Custom exceptions for AI provider errors
module AiProviders
  class ServiceError < StandardError; end
  class TimeoutError < ServiceError; end
  class ConnectionError < ServiceError; end
  class InvalidApiKeyError < ServiceError; end
end
