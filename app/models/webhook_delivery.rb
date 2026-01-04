# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_deliveries
#
#  id              :uuid             not null, primary key
#  webhook_id      :uuid             not null
#  event           :string(255)      not null
#  payload         :jsonb
#  status          :string(255)      default('pending'), not null
#  response_code   :integer
#  response_body   :text
#  error_message   :text
#  retry_count     :integer          default(0), not null
#  delivered_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_webhook_deliveries_on_webhook_id  (webhook_id)
#  index_webhook_deliveries_on_status      (status)
#  index_webhook_deliveries_on_event       (event)
#

class WebhookDelivery < ApplicationRecord
  belongs_to :webhook

  validates :event, presence: true
  validates :status, inclusion: {in: %w[pending success failed retrying]}
  validates :retry_count, numericality: {greater_than_or_equal_to: 0}

  scope :pending, -> { where(status: "pending") }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :retrying, -> { where(status: "retrying") }
  scope :recent, -> { order(created_at: :desc) }

  MAX_RETRIES = 3
  RETRY_DELAYS = [1.minute, 5.minutes, 15.minutes].freeze

  def deliver!
    return if status == "success"

    begin
      response = make_request

      if response.success?
        update!(
          status: "success",
          response_code: response.code,
          response_body: response.body,
          delivered_at: Time.current
        )
      else
        handle_failure(response)
      end
    rescue StandardError => e
      handle_error(e)
    end
  end

  def can_retry?
    retry_count < MAX_RETRIES && status != "success"
  end

  def next_retry_at
    return nil unless can_retry?

    delay = RETRY_DELAYS[retry_count] || RETRY_DELAYS.last
    created_at + delay
  end

  def retry!
    return unless can_retry?

    update!(
      status: "retrying",
      retry_count: retry_count + 1
    )

    WebhookDeliveryJob.perform_later(id, delay: next_retry_at - Time.current)
  end

  private

  def make_request
    uri = URI(webhook.url)

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "NEMO-Webhook/1.0"
    request["X-NEMO-Event"] = event
    request["X-NEMO-Delivery"] = id
    request["X-NEMO-Signature"] = generate_signature if webhook.secret.present?

    request.body = build_payload.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 30
    http.open_timeout = 10

    http.request(request)
  end

  def build_payload
    {
      id: id,
      event: event,
      created_at: created_at.iso8601,
      data: payload,
      webhook: {
        id: webhook.id,
        name: webhook.name
      },
      mission: {
        id: webhook.mission.id,
        name: webhook.mission.name,
        shortcode: webhook.mission.shortcode
      }
    }
  end

  def generate_signature
    payload = build_payload.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", webhook.secret, payload)
    "sha256=#{signature}"
  end

  def handle_failure(response)
    if can_retry?
      update!(
        status: "retrying",
        response_code: response.code,
        response_body: response.body,
        retry_count: retry_count + 1
      )

      WebhookDeliveryJob.perform_later(id, delay: next_retry_at - Time.current)
    else
      update!(
        status: "failed",
        response_code: response.code,
        response_body: response.body,
        error_message: "HTTP #{response.code}: #{response.message}"
      )
    end
  end

  def handle_error(error)
    if can_retry?
      update!(
        status: "retrying",
        error_message: error.message,
        retry_count: retry_count + 1
      )

      WebhookDeliveryJob.perform_later(id, delay: next_retry_at - Time.current)
    else
      update!(
        status: "failed",
        error_message: error.message
      )
    end
  end
end
