# frozen_string_literal: true

# Email notifier, to send various emails
class Notifier < ApplicationMailer
  def password_reset_instructions(user, mission: nil)
    build_reset_url(user)
    mail(to: user.email, reply_to: reply_to(mission),
         subject: t("notifier.password_reset_instructions"))
  end

  def intro(user, mission: nil)
    @user = user
    build_reset_url(user)
    mail(to: user.email, reply_to: reply_to(mission),
         subject: t("notifier.welcome", site: Settings.site_name))
  end

  def sms_token_change_alert(mission)
    raise ArgumentError, "Mission must not be nil" unless mission

    @mission = mission
    @site_name = Settings.site_name
    mail(to: reply_to(mission), reply_to: reply_to(mission),
         subject: t("notifier.sms_token_change.subject", mission_name: mission.name))
  end

  private

  def reply_to(mission)
    return [] if mission.nil?
    User.with_roles(mission, :coordinator).pluck(:email).uniq[0, 10] # Max of 10 reply to, should be rare.
  end

  def build_reset_url(user)
    @reset_url = edit_password_reset_url(user.perishable_token,
      mode: nil, mission_name: nil, locale: user.pref_lang)
  end
end
