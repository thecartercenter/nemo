# frozen_string_literal: true

# Methods pertaining to resetting user passwords in a controller action.
module PasswordResettable
  extend ActiveSupport::Concern

  def reset_password_if_requested(user)
    user.reset_password && user.save if %w[email print].include?(user.reset_password_method)
    deliver_email(user) if user.reset_password_method == "email"
  end

  def deliver_password_reset_instructions(user)
    user.reset_perishable_token!
    Notifier.password_reset_instructions(user).deliver_now
  end

  def deliver_user_intro(user)
    user.reset_perishable_token!
    Notifier.intro(user).deliver_now
  end

  private

  def deliver_email(user)
    # only send intro if he/she has never logged in
    if (user.login_count || 0).positive?
      deliver_password_reset_instructions(user)
    else
      deliver_user_intro(user)
    end
  end
end
