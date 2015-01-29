class Sms::Incoming < Sms::Message
  # User may be nil if sent from an unrecognized number.
  belongs_to :user

  # Lookup the sender.
  before_create do
    self.user ||= User.by_phone(from)
    return true
  end

  def self.search_qualifiers
    super + [
      Search::Qualifier.new(name: "user", col: "users.login", type: :text, assoc: :users, default: true),
      Search::Qualifier.new(name: "name", col: "users.name", type: :text, assoc: :users, default: true),
      Search::Qualifier.new(name: "number", col: "sms_messages.from", type: :text, default: true),
    ]
  end

  def sender
    user
  end

  def recipient_count
    1
  end

  def recipient_numbers
    [to]
  end

  def recipient_hashes(options = {})
    [user: User::ELMO, phone: to]
  end
end
