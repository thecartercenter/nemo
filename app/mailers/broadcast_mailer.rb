# frozen_string_literal: true

# Sends broadcast emails.
class BroadcastMailer < ApplicationMailer
  def broadcast(to:, subject:, body:, mission:)
    @body = body
    @mission = mission
    @site_name = site_name

    # TODO: We should send a separate email to each recipient
    # like we do with an SMS broadcast
    mail(to: to, subject: "[#{site_name}] #{subject}")
  end
end
