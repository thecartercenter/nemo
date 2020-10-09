# frozen_string_literal: true

Delayed::Worker.logger = Logger.new(Rails.root.join("log/dj.log"))
Delayed::Worker.logger.extend(ActiveSupport::Logger.broadcast(Logger.new(STDOUT))) if Rails.env.development?

Delayed::Worker.queue_attributes = {
  default: {priority: 0},
  odata: {priority: 10}
}

# Make DJ interrupt a job that is running when systemd attempts to stop or restart the DJ process.
# When systemd stops a service, by default, a SIGTERM is sent, followed by 90 seconds of waiting
# followed by a SIGKILL. By default, DJ does nothing with the SIGTERM signal, so after 90 seconds,
# the job will be killed abruptly and left to languish in the jobs table as a stuck job.
# This setting means that, instead, when SIGTERM is received, an exception will be thrown and so
# the job will fail and be returned to the jobs queue, making it available to other workers
# once the process restarts.
Delayed::Worker.raise_signal_exceptions = :term
