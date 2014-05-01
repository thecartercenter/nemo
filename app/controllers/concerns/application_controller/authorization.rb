module Concerns::ApplicationController::Authorization
  extend ActiveSupport::Concern

  # makes sure admin_mode is not true if user is not admin
  def protect_admin_mode
    if admin_mode? && cannot?(:view, :admin_mode)
      params[:mode] = nil
      raise CanCan::AccessDenied.new("not authorized for admin mode", :view, :admin_mode)
    end
  end
end