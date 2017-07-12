class PingController < ApplicationController
  skip_authorization_check

  # Used by uptime checker
  def show
    @tests = {}
    @tests[:dj_running] = pid_from_file_is_running("tmp/pids/delayed_job.pid")
    @ok = @tests.values.all?
    render layout: nil, formats: :text, status: @ok ? 200 : 503
  end

  private

  def pid_from_file_is_running(path)
    !!Process.kill(0, File.read(Rails.root.join(path)).to_i)
  rescue Errno::ENOENT, Errno::ESRCH
    false
  end

  def seconds_since_file_modified(path)
    (Time.now - File.stat(Rails.root.join(path)).mtime).to_i
  rescue Errno::ENOENT
    1_000_000
  end
end
