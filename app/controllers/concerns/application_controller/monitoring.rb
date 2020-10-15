# frozen_string_literal: true

# ApplicationController methods related to Scout monitoring/analytics.
module ApplicationController::Monitoring
  extend ActiveSupport::Concern

  def set_scout_context
    ScoutApm::Context.add_user(username: current_user&.login)
    ScoutApm::Context.add(locale: I18n.locale,
                          mode: params[:mode],
                          mission_name: current_mission&.compact_name)
  end
end
