class AdminMailer < ActionMailer::Base
  default :from => configatron.site_email
  
  # mails an error report to the webmaster
  def error(exception, session = nil, params = nil, env = nil, user = nil)
    @exception = exception
    @session = session
    @params = params
    @env = env
    @user = user
    path = env && env['REQUEST_URI'] && (": " + env['REQUEST_URI']) || ""
    mail(:to => configatron.webmaster_emails, :subject => "Error#{path}")
  end
end
