# frozen_string_literal: true

# Checks and displays app status.
class PingController < ApplicationController
  skip_authorization_check

  # Used by uptime checker
  def show
    @site_name = current_mission_config.site_name
    @tests = {}
    @tests[:dj_running] = Utils::DelayedJobChecker.instance.ok?
    @ok = @tests.values.all?
    @version = Cnfg.system_version(detailed: true)
    render(layout: nil, formats: :text, status: @ok ? :ok : :service_unavailable)
  end
end
