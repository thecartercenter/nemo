class AdminMailer < ActionMailer::Base
  default :from => configatron.site_email

  # mails an error report to the webmaster
  def error(exception, session = nil, params = nil, env = nil, user = nil)
    @exception = exception
    @session = session
    @params = params
    @env = env
    @user = user
    @hostname = env['SERVER_NAME'] || env['HTTP_HOST'] || env['HTTP_ORIGIN'] if env
    @rails_env = Rails.env
    path = (env && env['REQUEST_URI']) ? (": " + env['REQUEST_URI']) : ""
    exception_name = @exception ? ": #{@exception.class} #{@exception.message}" : ""
    mail(:to => configatron.webmaster_emails, :subject => "Error#{path}#{exception_name}")
  end
end
