# frozen_string_literal: true

# Destroy User objects in batches
class UserDestroyer < EnumeratingDestroyer
  def initialize(user:, **params)
    self.current_user = user
    super(**params)
  end

  protected

  attr_accessor :current_user

  def can_deactivate?
    true
  end

  def skip?(user)
    user == current_user
  end
end
