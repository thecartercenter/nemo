# frozen_string_literal: true

# Methods pertaining to resetting user passwords in a controller action.
module PasswordResettable
  extend ActiveSupport::Concern

  # Resets password. Sends appropriate email depending on notify_method.
  def reset_password(user, mission: nil, notify_method: nil)
    return unless %w[email print].include?(notify_method)
    user.reset_password && user.save(validate: false)
    return unless notify_method == "email"
    send_reset_password_instructions(user, mission: mission)
  end

  # Sends appropriate password reset email.
  def send_reset_password_instructions(user, mission: nil)
    # Only send intro if user has never logged in. Else send password reset email.
    user.reset_perishable_token!
    if (user.login_count || 0).positive?
      Notifier.password_reset_instructions(user, mission: mission).deliver_now
    else
      Notifier.intro(user, mission: mission).deliver_now
    end
  end
end
