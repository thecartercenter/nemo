class Sms::Incoming < Sms::Message
  # Lookup the sender. We do this here in addition to
  # in the decoder because having this information available
  # as early as possible allows us to better handle error messages
  # and saves the decoder some work if we already have the user assigned.
  before_create :set_user

  def sender
    user
  end

  def recipient_count
    1
  end

  def recipient_numbers
    [to] # `to` may be nil
  end

  # Returns a set of hashes of form {user: x, phone: y} for recipients.
  def recipient_hashes(options = {})
    [user: User.site_user, phone: to]
  end

  private

  def set_user
    matching_users = User.by_phone(from).active
    self.user ||= matching_users.first if matching_users.count == 1
    true
  end
end
