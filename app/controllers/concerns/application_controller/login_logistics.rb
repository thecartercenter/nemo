module Concerns::ApplicationController::LoginLogistics
  extend ActiveSupport::Concern

  # tasks that should be run after the user successfully logs in OR successfully resets their password
  # returns false if no further stuff should happen (redirect), true otherwise
  def post_login_housekeeping
    # get the session
    @user_session = UserSession.find

    # reset the perishable token for security's sake
    @user_session.user.reset_perishable_token!

    return true
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
      render(:text => "LOGIN_REQUIRED", :status => 401)
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
