# frozen_string_literal: true

# This controller is just for testing path helpers. It's not for use outside of test mode.
class RouteTestsController < ApplicationController
  skip_authorization_check
  layout false

  def basic_mode
  end

  def mission_mode
  end

  def admin_mode
  end
end
