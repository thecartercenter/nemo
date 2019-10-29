# frozen_string_literal: true

# Error when revision number is too high (ODK only supports 2 digits)
class RevisionTooHighError < StandardError
  def initialize(msg = "Revision number can't be more than 2 digits")
    super
  end
end
