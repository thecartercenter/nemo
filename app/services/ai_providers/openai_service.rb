# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# OpenAI API integration for AI validation
class AiProviders::OpenaiService < AiProviders::BaseService
  API_BASE_URL = "https://api.openai.com/v1"

  def initialize(api_key:, model: "gpt-3.5-turbo", timeout: 30)
    super
    validate_model!
  end

  def call_ai_model(prompt, options = {})
    return default_error_response unless available?

    uri = URI("#{API_BASE_URL}/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = timeout
    http.open_timeout = timeout

    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = build_request_body(prompt, options).to_json

    response = http.request(request)
    handle_http_response(response)
  rescue Net::TimeoutError, Timeout::Error => e
    raise AiProviders::TimeoutError, "AI service request timed out after #{timeout}s: #{e.message}"
  rescue SocketError, Errno::ECONNREFUSED => e
    raise AiProviders::ConnectionError, "Failed to connect to AI service: #{e.message}"
  rescue StandardError => e
    raise AiProviders::ServiceError, "AI service error: #{e.message}"
  end

  def estimate_cost(prompt_tokens, completion_tokens = 0)
    # Pricing as of 2024 (adjust as needed)
    pricing = {
      "gpt-3.5-turbo" => {input: 0.0015 / 1000, output: 0.002 / 1000},
      "gpt-4" => {input: 0.03 / 1000, output: 0.06 / 1000},
      "gpt-4-turbo" => {input: 0.01 / 1000, output: 0.03 / 1000}
    }

    model_pricing = pricing[model] || pricing["gpt-3.5-turbo"]
    (prompt_tokens * model_pricing[:input]) + (completion_tokens * model_pricing[:output])
  end

  private

  def validate_model!
    valid_models = %w[gpt-3.5-turbo gpt-4 gpt-4-turbo gpt-4o]
    return if valid_models.include?(model)

    raise ArgumentError, "Invalid OpenAI model: #{model}. Valid models: #{valid_models.join(', ')}"
  end

  def build_request_body(prompt, options)
    {
      model: model,
      messages: [
        {
          role: "system",
          content: build_system_prompt(options)
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: options[:temperature] || 0.3, # Lower temperature for more consistent validation
      max_tokens: options[:max_tokens] || 1000,
      response_format: {type: "json_object"} # Request structured JSON response
    }
  end

  def build_system_prompt(_options)
    <<~PROMPT
      You are a data quality validation assistant. Analyze form responses and provide structured feedback.

      Respond ONLY with valid JSON in this exact format:
      {
        "confidence": 0.0-1.0,
        "is_valid": true/false,
        "issues": ["issue1", "issue2"],
        "suggestions": ["suggestion1", "suggestion2"],
        "explanation": "Brief explanation of validation result"
      }

      - confidence: Your confidence in the validation (0.0 = not confident, 1.0 = very confident)
      - is_valid: Whether the data appears valid based on your analysis
      - issues: Array of specific problems found (empty if none)
      - suggestions: Array of recommendations to improve data quality
      - explanation: Brief explanation of your assessment
    PROMPT
  end

  def handle_http_response(response)
    case response
    when Net::HTTPSuccess
      parse_openai_response(JSON.parse(response.body))
    else
      error_body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        {"error" => {"message" => response.body}}
      end
      error_message = error_body.dig("error", "message") || "HTTP #{response.code}"
      raise AiProviders::ServiceError, "AI service returned error: #{error_message}"
    end
  end

  def parse_openai_response(response)
    content = response.dig("choices", 0, "message", "content")
    return default_error_response unless content

    # Parse JSON response
    parsed = JSON.parse(content)

    {
      confidence: normalize_confidence(parsed["confidence"]),
      is_valid: parsed["is_valid"] || false,
      issues: Array(parsed["issues"] || []),
      suggestions: Array(parsed["suggestions"] || []),
      explanation: parsed["explanation"] || "AI validation completed",
      usage: response["usage"] # Track token usage for cost estimation
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse OpenAI JSON response: #{e.message}\nContent: #{content}")
    # Try to extract information from unstructured response
    fallback_parse(content)
  end

  def normalize_confidence(value)
    return 0.5 unless value

    conf = value.to_f
    conf = 0.0 if conf < 0.0
    conf = 1.0 if conf > 1.0
    conf
  end

  def fallback_parse(content)
    # Fallback: try to extract information from text response
    issues = content.scan(/issue[:\s]+(.+?)(?:\n|$)/i).flatten
    suggestions = content.scan(/suggestion[:\s]+(.+?)(?:\n|$)/i).flatten

    {
      confidence: 0.5, # Default confidence for unstructured response
      is_valid: !content.downcase.include?("invalid") && !content.downcase.include?("error"),
      issues: issues.any? ? issues : [],
      suggestions: suggestions.any? ? suggestions : [],
      explanation: content.truncate(500)
    }
  end
end
