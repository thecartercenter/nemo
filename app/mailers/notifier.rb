class Notifier < ActionMailer::Base
  default(from: configatron.site_email)

  def password_reset_instructions(user)
    build_reset_url(user)
    mail(to: user.email, subject: t("notifier.password_reset_instructions"))
  end

  def intro(user)
    @user = user
    build_reset_url(user)
    mail(to: user.email, subject: t("notifier.welcome", site: configatron.site_name))
  end

  private

  def build_reset_url(user)
    @reset_url = edit_password_reset_url(user.perishable_token,
      mode: nil, mission_name: nil, locale: user.pref_lang)
  end
end
