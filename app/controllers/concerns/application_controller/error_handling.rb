module Concerns::ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  # notifies the webmaster of an error in production mode
  def notify_error(exception)
    if Rails.env == "production"
      begin
        AdminMailer.error(exception, session.to_hash, params, request.env, current_user).deliver_now
      rescue
        logger.error("ERROR SENDING ERROR NOTIFICATION: #{$!.to_s}: #{$!.message}\n#{$!.backtrace.to_a.join("\n")}")
      end
    end
    # Still show error page.
    raise exception
  end

  def handle_not_found(exception)
    raise exception
  end

  def handle_invalid_authenticity_token(exception)
    raise exception
  end
end
