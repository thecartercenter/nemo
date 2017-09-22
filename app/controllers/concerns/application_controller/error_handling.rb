module Concerns::ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  def handle_not_found(exception)
    raise exception
  end

  def handle_invalid_authenticity_token(exception)
    raise exception
  end
end
