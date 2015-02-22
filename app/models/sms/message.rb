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

  # User may be nil if sent from an unrecognized number or replying to someone not recognized as user.
  belongs_to :user

  before_create :default_sent_at
  after_initialize :normalize_numbers

  # order by id after created_at to make sure they are in creation order
  scope(:latest_first, ->{ order('created_at DESC, id DESC') })

  def self.is_shortcode?(phone)
    phone =~ /[a-z]/i || phone.size <= 6
  end

  # Remove all non-digit chars and add a plus at the front.
  # (unless the number looks like a shortcode, in which case we leave it alone)
  def self.normalize_phone(phone)
    phone.blank? ? nil : (is_shortcode?(phone) ? phone : ("+" + phone.gsub(/[^\d]/, "")))
  end

  def self.search_qualifiers
    # We pass explicit SQL here or else we end up with an INNER JOIN which excludes any message
    # with no associated user.
    user_assoc = 'LEFT JOIN users ON users.id = sms_messages.user_id'

    [
      Search::Qualifier.new(name: "content", col: "sms_messages.body", type: :text, default: true),
      Search::Qualifier.new(name: "type", col: "sms_messages.type", type: :text),
      Search::Qualifier.new(name: "date", col: "DATE(sms_messages.created_at)", type: :scale),
      Search::Qualifier.new(name: "datetime", col: "sms_messages.created_at", type: :scale),
      Search::Qualifier.new(name: "username", col: "users.login", type: :text, assoc: user_assoc, default: true),
      Search::Qualifier.new(name: "name", col: "users.name", type: :text, assoc: user_assoc, default: true),
      Search::Qualifier.new(name: "number", col: "sms_messages.to", type: :text, default: true)
    ]
  end

  # searches for sms messages
  # based on User.do_search
  def self.do_search(relation, query)
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # apply the needed associations
    relation = relation.joins(search.associations)

    # apply the conditions
    relation = relation.where(search.sql)
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

  def recipient_count
    raise NotImplementedError
  end

  def recipient_numbers
    raise NotImplementedError
  end

  def recipient_hashes(options = {})
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
