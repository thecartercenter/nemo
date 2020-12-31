# frozen_string_literal: true

# App-wide parent for all mailers.
class ApplicationMailer < ActionMailer::Base
  default from: configatron.site_email
end
