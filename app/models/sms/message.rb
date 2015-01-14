# models an sms message, either incoming or outgoing
# gets created by adapters when messages are incoming
# and gets created by controllers and sent to adapters for sending when messages are outgoing
#
# to          a string holding a phone number in ITU E.123 format (e.g. "+14445556666")
#             can be nil in case of an incoming message
# from        a string holding a single phone number. can be nil in case of an outgoing message.
# body        a string holding the body of the message
# sent_at     the time the message was sent/received
class Sms::Message < ActiveRecord::Base
  include MissionBased

  belongs_to :mission

  before_create :default_sent_at
  after_initialize :normalize_numbers

  def self.is_shortcode?(phone)
    phone =~ /[a-z]/i || phone.size <= 6
  end

  # Remove all non-digit chars and add a plus at the front.
  # (unless the number looks like a shortcode, in which case we leave it alone)
  def self.normalize_phone(phone)
    phone.blank? ? nil : (is_shortcode?(phone) ? phone : ("+" + phone.gsub(/[^\d]/, "")))
  end

  def received_at
    type == "Sms::Incoming" ? created_at : nil
  end

  def from_shortcode?
    self.class.is_shortcode?(from)
  end

  def sender
    raise NotImplementedError
  end

  def recipients
    raise NotImplementedError
  end

  def recipient_hashes
    raise NotImplementedError
  end

  private

    # sets sent_at to now unless it's already set
    def default_sent_at
      self.sent_at = Time.zone.now unless sent_at
    end

    # normalizes all phone numbers to ITU format
    def normalize_numbers
      self.from = self.class.normalize_phone(from)
      self.to = self.class.normalize_phone(to) unless to.nil?
    end
end
