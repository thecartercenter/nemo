class PingController < ApplicationController
  skip_authorization_check

  # Used by uptime checker
  def show
    @tests = {}
    @tests[:dj_running] = DelayedJobChecker.new.running?
    @ok = @tests.values.all?
    @version = configatron.system_version
    render layout: nil, formats: :text, status: @ok ? 200 : 503
  end

  private

  def seconds_since_file_modified(path)
    (Time.now - File.stat(Rails.root.join(path)).mtime).to_i
  rescue Errno::ENOENT
    1_000_000
  end
end
