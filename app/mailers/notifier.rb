# frozen_string_literal: true

# Email notifier, to send various emails
class Notifier < ActionMailer::Base
  default(from: configatron.site_email)

  def password_reset_instructions(user)
    build_reset_url(user)
    mail(to: user.email, reply_to: reply_to(user), subject: t("notifier.password_reset_instructions"))
  end

  def intro(user)
    @user = user
    build_reset_url(user)
    mail(to: user.email, reply_to: reply_to(user), subject: t("notifier.welcome", site: Settings.site_name))
  end

  private

  def reply_to(user)
    role = :coordinator
    user.missions.map { |msn| User.with_roles(msn, role).pluck(:email) }.flatten if user.missions.present?
  end

  def build_reset_url(user)
    @reset_url = edit_password_reset_url(user.perishable_token,
      mode: nil, mission_name: nil, locale: user.pref_lang)
  end
end
