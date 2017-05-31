# Serves as a model for the password reset form. Not persisted.
class PasswordReset
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :identifier

  def initialize(identifier: "")
    self.identifier = identifier
  end

  # Looks up the user matching the identifier. Returns nil if not found.
  def user
    User.find_by(email: identifier)
  end

  def persisted?
    false
  end
end
