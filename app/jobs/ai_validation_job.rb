# frozen_string_literal: true

class AiValidationJob < ApplicationJob
  queue_as :ai_validation

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(response_id)
    response = Response.find(response_id)
    AiValidationService.validate_response(response)
  rescue ActiveRecord::RecordNotFound
    # Response was deleted, nothing to do
  end
end
