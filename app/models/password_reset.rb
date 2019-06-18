# frozen_string_literal: true

# Serves as a model for the password reset form. Not persisted.
class PasswordReset
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :identifier

  def initialize(identifier: "")
    self.identifier = identifier
  end

  # Looks up the users matching the identifier. Returns empty array if none found.
  def matches
    (User.where(email: identifier).to_a << User.find_by(login: identifier)).compact
  end

  def persisted?
    false
  end
end
