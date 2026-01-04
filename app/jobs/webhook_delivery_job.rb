# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(webhook_delivery_id, delay: 0)
    sleep(delay) if delay > 0

    delivery = WebhookDelivery.find(webhook_delivery_id)
    delivery.deliver!
  rescue ActiveRecord::RecordNotFound
    # Webhook delivery was deleted, nothing to do
  end
end
