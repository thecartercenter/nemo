# frozen_string_literal: true

# Email notifier, to send various emails
class Notifier < ApplicationMailer
  def password_reset_instructions(user, mission: nil)
    @mission = mission
    @reset_url = reset_url(user)
    @site_name = site_name
    mail(to: user.email, reply_to: coordinator_emails(mission),
         subject: t("notifier.password_reset_instructions"))
  end

  def intro(user, mission: nil)
    @mission = mission
    @user = user
    @reset_url = reset_url(user)
    @site_name = site_name
    mail(to: user.email, reply_to: coordinator_emails(mission),
         subject: t("notifier.welcome", site: @site_name))
  end

  def sms_token_change_alert(mission)
    raise ArgumentError, "Mission must not be nil" unless mission
    @mission = mission
    @site_name = site_name
    all_emails = (coordinator_emails(mission) + admin_emails).uniq
    mail(to: all_emails, reply_to: all_emails,
         subject: t("notifier.sms_token_change.subject", mission_name: mission.name))
  end

  # params: item, error, response
  def bug_tracker_warning(params)
    @response = params[:response]
    @error = params[:error]
    @item = params[:item]

    mail(
      to: NEMO_WEBMASTER_EMAILS,
      reply_to: "no-reply@getnemo.org",
      subject: "[#{NEMO_URL_HOST} WARNING] (#{@error})"
    )
  end

  private

  def coordinator_emails(mission)
    return [] if mission.nil?
    User.with_roles(mission, :coordinator).active.pluck(:email).uniq[0, 10] # Max of 10, should be rare.
  end

  def admin_emails
    User.where(admin: true).active.pluck(:email)
  end

  def reset_url(user)
    edit_password_reset_url(user.perishable_token, mode: nil, mission_name: nil, locale: user.pref_lang)
  end
end
