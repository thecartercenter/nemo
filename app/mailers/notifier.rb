class Notifier < ActionMailer::Base  
  default(:from => configatron.site_email)
  
  def password_reset_instructions(user) 
    @reset_url = edit_password_reset_url(user.perishable_token, :protocol => configatron.mailer_url_protocol)  
    mail(:to => user.email, :subject => "Password Reset Instructions")
  end
  
  def intro(user)
    @user = user
    @reset_url = edit_password_reset_url(user.perishable_token, :protocol => configatron.mailer_url_protocol)
    mail(:to => user.email, :subject => "Welcome to #{configatron.site_name}")
  end    
end