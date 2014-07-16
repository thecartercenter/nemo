module Concerns::ApplicationController::Authorization
  extend ActiveSupport::Concern

  # makes sure admin_mode is not true if user is not admin
  def protect_admin_mode
    if admin_mode? && cannot?(:view, :admin_mode)
      params[:mode] = nil
      raise CanCan::AccessDenied.new("not authorized for admin mode", :view, :admin_mode)
    end
  end

  def handle_access_denied(exception)
    # set flag for tests to check
    @access_denied = true

    # log to debug log
    Rails.logger.debug("ACCESS DENIED on #{exception.action} #{exception.subject.inspect} #{exception.message} " +
      "(Current Mission: #{current_mission.try(:name)}; Current Role: #{current_user.try(:role, current_mission)})")

    # if not logged in, offer a login page
    if !current_user
      flash[:error] = I18n.t("unauthorized.must_login")
      redirect_to_login

    # else if there was just a mission change, we need to handle specially
    elsif flash[:missionchange]
      # if the request was a CRUD, try redirecting to the index, or root if no permission
      if Ability::CRUD.include?(exception.action) && current_ability.can?(:index, exception.subject.class)
        redirect_to(:controller => controller_name, :action => :index)
      else
        redirect_to(mission_root_url)
      end

    # else if this is not an html request, render an empty 401 (unauthorized).
    elsif !request.format.html?
      render(:nothing => true, :status => 401)

    # else redirect to welcome page with error
    else
      redirect_to(unauthorized_path)
    end
  end
end