# frozen_string_literal: true

module ApplicationController::Caching
  extend ActiveSupport::Concern

  def disable_client_caching
    # Disable client side caching, including back button
    # response.headers["Cache-Control"] = "no-cache, max-age=0, must-revalidate, no-store"
  end
end
