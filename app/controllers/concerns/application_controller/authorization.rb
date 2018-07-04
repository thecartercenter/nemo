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
      "(Mission: #{current_mission.try(:name)}; " +
      "User: #{current_user.try(:login)}; " +
      "Role: #{current_user.try(:role, current_mission)}; " +
      "Admin?: #{current_user.try(:admin?) ? 'Yes' : 'No'}")

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

    # else if this is not an html request, render an empty 403 (forbidden).
    elsif !request.format.html?
      render(:body => nil, :status => 403)

    # else redirect to welcome page with error
    else
      redirect_to(unauthorized_path)
    end
  end

  # This method is intended to be called as a before_action from controllers
  # that require a recent login in addition to their normal authentication and
  # authorization. If a recent login is not found, a RecentLoginRequireError
  # will be thrown. The default handling for this error in
  # ApplicationController is to call handle_recent_login_required.
  def require_recent_login(options={})
    unless current_user && current_user.current_login_recent?(options[:max_age])
      raise RecentLoginRequiredError
    end
  end

  def handle_recent_login_required(exception)
    if request.xhr?
      flash[:error] = nil
      render(:plain => "RECENT_LOGIN_REQUIRED", :status => 401)
    else
      store_location
      redirect_to(new_login_confirmation_url)
    end
  end

  def offline_mode?
    configatron.offline_mode
  end
end
