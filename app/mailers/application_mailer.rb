# frozen_string_literal: true

# App-wide parent for all mailers.
class ApplicationMailer < ActionMailer::Base
  default from: configatron.site_email

  def broadcast(recips, subj, msg)
    @msg = msg
    # TODO: We should send a separate email to each recipient
    # like we do with an SMS broadcast
    mail(to: recips, subject: "[#{Settings.broadcast_tag}] #{subj}")
  end
end
