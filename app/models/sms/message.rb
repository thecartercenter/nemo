# models an sms message, either incoming or outgoing
# gets created by adapters when messages are incoming
# and gets created by controllers and sent to adapters for sending when messages are outgoing
#
# to          a string or an array of strings holding phone numbers in ITU E.123 format (e.g. ["+14445556666", "+14445556667"])
#             can be nil in case of an incoming message
# from        a string holding a single phone number. can be nil in case of an outgoing message.
# body        a string holding the body of the message
# sent_at     the time the message was sent/received
class Sms::Message < ActiveRecord::Base
  include MissionBased

  serialize :to, JSON

  belongs_to :mission

  after_initialize :arrayify_to
  before_create :default_sent_at
  after_initialize :normalize_numbers

  scope(:newest_first, order("sent_at DESC"))
  scope(:newly_created_first, order("created_at DESC"))

  def self.is_shortcode?(phone)
    phone =~ /[a-z]/i || phone.size <= 6
  end

  # Remove all non-digit chars and add a plus at the front.
  # (unless the number looks like a shortcode, in which case we leave it alone)
  def self.normalize_phone(phone)
    phone.nil? ? nil : (is_shortcode?(phone) ? phone : ("+" + phone.gsub(/[^\d]/, "")))
  end

  def received_at
    (direction == "incoming") ? created_at : nil
  end

  def from_shortcode?
    self.class.is_shortcode?(from)
  end

  private

    # sets sent_at to now unless it's already set
    def default_sent_at
      self.sent_at = Time.zone.now unless sent_at
    end

    # makes sure the to field is an array, unless it's nil
    def arrayify_to
      unless to.nil? || to.is_a?(Array)
        self.to = Array.wrap(to)
      end
    end

    # normalizes all phone numbers to ITU format
    def normalize_numbers
      self.from = self.class.normalize_phone(from)
      to.each_with_index{|n, i| self.to[i] = self.class.normalize_phone(n)} unless to.nil?
    end
end
