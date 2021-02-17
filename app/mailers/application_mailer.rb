# frozen_string_literal: true

# App-wide parent for all mailers.
class ApplicationMailer < ActionMailer::Base
  # Normally here we'd set the default from address, but since the site name can vary
  # by theme, we have to do it in the overridden mail method below.

  delegate :site_name, :site_email_with_name, to: :mission_config

  private

  def mail(**params)
    # @mission has to be set by the mailer method for theme settings to be respected.
    params[:from] ||= site_email_with_name
    super(**params)
  end

  def mission_config
    # If @mission hasn't been set by the mailer yet, this will fall back to the root setting.
    @mission_config ||= Setting.for_mission(@mission)
  end
end
