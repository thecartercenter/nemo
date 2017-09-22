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
    data = {}

    if current_user
      data[:user] = {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email
      }
    end

    request.env["exception_notifier.exception_data"] = data
  end
end
