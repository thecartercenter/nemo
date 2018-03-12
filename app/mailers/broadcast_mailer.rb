class BroadcastMailer < ActionMailer::Base
  default :from => configatron.site_email

  def broadcast(recips, subj, msg)
    @msg = msg
    mail(to: recips, subject: "[#{Settings.broadcast_tag}] #{subj}")
  end
end
