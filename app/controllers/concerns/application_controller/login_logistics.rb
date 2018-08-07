module Concerns::ApplicationController::LoginLogistics
  extend ActiveSupport::Concern

  # logs out user if not already logged out
  # might be called /after/ get_user_and_mission due to filter order
  # so should undo that method's changes
  def ensure_logged_out
    if user_session = UserSession.find
      user_session.destroy
      @current_user = nil
      @current_mission = nil
    end
  end

  # Tasks that should be run after the user successfully logs in OR successfully resets their password
  # Redirects to the appropriate place.
  def post_login_housekeeping(options = {})
    # Get the session
    @user_session = UserSession.find

    # Reset the perishable token for security's sake
    @user_session.user.reset_perishable_token!

    # Set the locale based on the user's pref_lang (if it's supported)
    set_locale_or_default(@user_session.user.pref_lang)

    return if options[:dont_redirect]

    # Redirect admin's first login to password reset.
    if @user_session.user.admin? && @user_session.user.login_count <= 1
      flash[:success] = t("user.set_admin_password")
      redirect_to edit_user_path(@user_session.user)
    else
      # Redirect to most relevant mission
      best_mission = @user_session.user.best_mission
      redirect_back_or_default best_mission ? mission_root_path(mission_name: best_mission.compact_name) : basic_root_path
    end
  end

  # resets the Rails session but preserves the :return_to key
  # used for security purposes
  def reset_session_preserving_return_to
    tmp = session[:return_to]
    reset_session
    session[:return_to] = tmp
  end

  # redirects to the login page
  # or if this is an ajax request, returns a 401 unauthorized error (but this should never happen)
  # in the latter case, the script should catch this error and redirect to the login page itself
  def redirect_to_login
    if request.xhr?
      flash[:error] = nil
      render(plain: "LOGIN_REQUIRED", status: :unauthorized)
    else
      store_location
      redirect_to(login_url)
    end
  end

  def store_location
    # if the request is a GET, then store as normal
    session[:return_to] = if request.get?
      request.fullpath
    # otherwise, store the referrer (if defined), since it doesn't make sense to store a URL for a different method
    elsif request.referrer
      request.referrer
    # otherwise store nothing
    else
      nil
    end
  end

  def forget_location
    session[:return_to] = nil
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    forget_location
  end
end
