module Concerns::ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  # notifies the webmaster of an error in production mode
  def notify_error(exception, options = {})
    if Rails.env == "production"
      begin
        AdminMailer.error(exception, session.to_hash, params, request.env, current_user).deliver
      rescue
        logger.error("ERROR SENDING ERROR NOTIFICATION: #{$!.to_s}: #{$!.message}\n#{$!.backtrace.to_a.join("\n")}")
      end
    end
    # still show error page unless requested not to
    raise exception unless options[:dont_re_raise]
  end

  def handle_not_found
    render nothing: true, status: 404
  end

  def handle_invalid_authenticity_token
    render nothing:true, status: 401
end
