# frozen_string_literal: true

# == Schema Information
#
# Table name: webhooks
#
#  id           :uuid             not null, primary key
#  name         :string(255)      not null
#  url          :string(500)      not null
#  events       :text             default([]), is an Array
#  secret       :string(255)
#  active       :boolean          default(TRUE), not null
#  retry_count  :integer          default(0), not null
#  last_triggered_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  mission_id   :uuid
#
# Indexes
#
#  index_webhooks_on_mission_id  (mission_id)
#  index_webhooks_on_active      (active)
#

class Webhook < ApplicationRecord
  include MissionBased

  belongs_to :mission
  has_many :webhook_deliveries, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :url, presence: true, length: { maximum: 500 }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true
  validates :secret, length: { maximum: 255 }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { where('events @> ?', [event].to_json) }

  WEBHOOK_EVENTS = %w[
    form.created
    form.updated
    form.published
    form.unpublished
    response.created
    response.updated
    response.submitted
    response.reviewed
    user.created
    user.updated
    user.assigned
    mission.created
    mission.updated
    data_export.completed
    notification.sent
  ].freeze

  validates :events, inclusion: { in: WEBHOOK_EVENTS }

  before_create :generate_secret
  before_save :normalize_events

  def trigger(event, payload)
    return unless active? && events.include?(event)

    delivery = webhook_deliveries.create!(
      event: event,
      payload: payload,
      status: 'pending'
    )

    WebhookDeliveryJob.perform_later(delivery.id)
    
    update!(last_triggered_at: Time.current)
  end

  def test_webhook
    test_payload = {
      event: 'webhook.test',
      data: {
        webhook_id: id,
        webhook_name: name,
        timestamp: Time.current.iso8601,
        mission: {
          id: mission.id,
          name: mission.name,
          shortcode: mission.shortcode
        }
      }
    }

    trigger('webhook.test', test_payload)
  end

  def success_rate
    return 0 if webhook_deliveries.count.zero?

    successful_deliveries = webhook_deliveries.where(status: 'success').count
    (successful_deliveries.to_f / webhook_deliveries.count * 100).round(2)
  end

  def recent_deliveries(limit = 10)
    webhook_deliveries.order(created_at: :desc).limit(limit)
  end

  private

  def generate_secret
    self.secret ||= SecureRandom.hex(32)
  end

  def normalize_events
    self.events = events.map(&:strip).reject(&:blank?).uniq
  end
end