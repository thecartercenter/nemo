# frozen_string_literal: true

module ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  # If we handle these errors in here and then reraise them, they won't generate exception notifications.
  def handle_not_found(exception)
    raise exception
  end

  def handle_invalid_authenticity_token(exception)
    raise exception
  end

  # Add some context right away, before we do things like load the mission
  # which could theoretically cause crashes.
  def set_initial_exception_context
    Raven.extra_context(params: params.to_unsafe_h)
  end

  def prepare_exception_notifier
    Raven.tags_context(locale: I18n.locale,
                       mode: params[:mode],
                       mission: current_mission&.compact_name)

    return unless current_user

    id, name, login, email = current_user.values_at(:id, :name, :login, :email)

    request.env["exception_notifier.exception_data"] = {
      user: {id: id, name: name, email: email}
    }

    # Slightly different allowable parameters.
    Raven.user_context(id: id, username: login, email: email)
  end

  def render_not_found
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404"), layout: false, status: :not_found }
      format.any { head :not_found }
    end
  end
end
