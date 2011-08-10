class BroadcastMailer < ActionMailer::Base
  default :from => configatron.site_email
  
  def broadcast(recips, subj, msg)
    s = configatron.broadcast_tag + " " + (subj || "")
    @msg = msg
    mail(:to => recips.collect{|r| r.email}.compact, :subject => s)
  end
end
