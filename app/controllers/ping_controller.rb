# frozen_string_literal: true

# Checks and displays app status.
class PingController < ApplicationController
  skip_authorization_check

  # Used by uptime checker
  def show
    @tests = {}
    @tests[:dj_running] = Utils::DelayedJobChecker.instance.ok?
    @ok = @tests.values.all?
    @version = Cnfg.system_version
    render(layout: nil, formats: :text, status: @ok ? :ok : :service_unavailable)
  end
end
