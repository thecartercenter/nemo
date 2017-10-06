module Concerns::ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  # If we handle these errors in here and then reraise them, they won't generate exception notifications.
  def handle_not_found(exception)
    raise exception
  end

  def handle_invalid_authenticity_token(exception)
    raise exception
  end

  def prepare_exception_notifier
    if current_user
      request.env["exception_notifier.exception_data"] = {
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email
        }
      }
    end
  end

  # Temporary bug chasing code
  def check_rank_fail
    if Rails.configuration.x.rank_fail_warned.blank? && (FormItem.rank_gaps? || FormItem.duplicate_ranks?)
      Rails.configuration.x.rank_fail_warned = true # Don't warn again until app restarted.
      `pg_dump #{ActiveRecord::Base.connection.current_database} > #{Rails.root}/tmp/rankfail-#{Time.current.strftime('%Y%m%d%H%M')}.sql`
      ExceptionNotifier.notify_exception(StandardError.new("Last request introduced rank issues. DB dumped."))
    end
  end
end
