# frozen_string_literal: true

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

  def render_not_found
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404"), layout: false, status: :not_found }
      format.any { head :not_found }
    end
  end
end
