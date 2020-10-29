# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: sms_messages
#
#  id                                                                   :uuid             not null, primary key
#  adapter_name                                                         :string(255)      not null
#  auth_failed                                                          :boolean          default(FALSE), not null
#  body                                                                 :text             not null
#  from                                                                 :string(255)
#  reply_error_message                                                  :string
#  sent_at                                                              :datetime         not null
#  to                                                                   :string(255)
#  type                                                                 :string(255)      not null
#  created_at                                                           :datetime         not null
#  updated_at                                                           :datetime         not null
#  broadcast_id                                                         :uuid
#  mission_id(Can't set null false due to missionless SMS receive flow) :uuid
#  reply_to_id                                                          :uuid
#  user_id                                                              :uuid
#
# Indexes
#
#  index_sms_messages_on_body          (body)
#  index_sms_messages_on_broadcast_id  (broadcast_id)
#  index_sms_messages_on_created_at    (created_at)
#  index_sms_messages_on_from          (from)
#  index_sms_messages_on_mission_id    (mission_id)
#  index_sms_messages_on_reply_to_id   (reply_to_id)
#  index_sms_messages_on_to            (to)
#  index_sms_messages_on_type          (type)
#  index_sms_messages_on_user_id       (user_id)
#
# Foreign Keys
#
#  sms_messages_broadcast_id_fkey  (broadcast_id => broadcasts.id) ON DELETE => restrict ON UPDATE => restrict
#  sms_messages_mission_id_fkey    (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  sms_messages_reply_to_id_fkey   (reply_to_id => sms_messages.id) ON DELETE => restrict ON UPDATE => restrict
#  sms_messages_user_id_fkey       (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# models an sms message, either incoming or outgoing
# gets created by adapters when messages are incoming
# and gets created by controllers and sent to adapters for sending when messages are outgoing
#
# to          a string holding a phone number in ITU E.123 format (e.g. "+14445556666")
#             can be nil in case of an incoming message
# from        a string holding a single phone number. can be nil in case of an outgoing message.
# body        a string holding the body of the message
# sent_at     the time the message was sent/received
class Sms::Message < ApplicationRecord
  include MissionBased

  belongs_to :mission

  # User may be nil if sent from an unrecognized number or replying to someone not recognized as user.
  belongs_to :user

  before_create :default_sent_at

  # order by id after created_at to make sure they are in creation order
  scope(:latest_first, -> { order("created_at DESC, id DESC") })
  scope :since, ->(time) { where("created_at > ?", time) }

  def received_at
    type == "Sms::Incoming" ? created_at : nil
  end

  def from_shortcode?
    PhoneNormalizer.is_shortcode?(from)
  end

  def sender
    raise NotImplementedError
  end

  def recipient_count
    raise NotImplementedError
  end

  def recipient_numbers
    raise NotImplementedError
  end

  def recipient_hashes(_options = {})
    raise NotImplementedError
  end

  def to=(number)
    self[:to] = PhoneNormalizer.normalize(number)
  end

  def from=(number)
    self[:from] = PhoneNormalizer.normalize(number)
  end

  private

  # sets sent_at to now unless it's already set
  def default_sent_at
    self.sent_at = Time.current unless sent_at
  end
end
