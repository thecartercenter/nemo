class Notifier < ActionMailer::Base
  default(:from => configatron.site_email)

  def password_reset_instructions(user)
    build_reset_url(user)
    mail(:to => user.email, :subject => t("notifier.password_reset_instructions")).deliver_now
  end

  def intro(user)
    @user = user
    build_reset_url(user)
    mail(:to => user.email, :subject => t("notifier.welcome", :site => configatron.site_name)).deliver_now
  end

  private

  def build_reset_url(user)
    @reset_url = edit_password_reset_url(user.perishable_token, :mode => nil, :mission_name => nil, :protocol => configatron.mailer_url_protocol)
  end
end