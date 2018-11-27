# frozen_string_literal: true

module Utils
  # Checks if DelayedJob is running. Used in ping and operations controllers.
  class DelayedJobChecker
    include Singleton

    def ok?
      # Are there any jobs created more than 10 seconds ago that haven't been picked up?
      # If not, then we must assume DJ is running. But if there are, AND there are no jobs
      # currently running (locked), DJ must not be running.
      !old_non_locked_jobs? || locked_jobs?
    end

    private

    def locked_jobs?
      Delayed::Job.where(failed_at: nil).where.not(locked_at: nil).any?
    end

    def old_non_locked_jobs?
      Delayed::Job
        .where(locked_at: nil, failed_at: nil)
        .where("EXTRACT(EPOCH FROM (NOW() - created_at)) > 10").any?
    end
  end
end
