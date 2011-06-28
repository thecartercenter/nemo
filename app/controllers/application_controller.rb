class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter(:set_default_title)
  before_filter(:mailer_set_url_options)
  before_filter(:init_js_array)
  
  helper_method :current_user_session, :current_user, :authorized?
require 'authlogic'
  protected
    def init_js_array
      @js = []
    end
    
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end
    
    def authorize
      # make sure user has permissions
      begin
        Permission.authorize(:user => current_user, :controller => controller_name, :action => action_name, :request => params)
        return true
      rescue PermissionError
        store_location
        # if the user needs to login, send them to the login page
        flash[:error] = $!.to_s
        redirect_to((flash[:error].match(/must login/) ? new_user_session_path : no_permissions_path))
        # halt the rest of the action
        return false
      end
    end 
    
    def authorized?(params)
      return Permission.authorized?(params.merge(:user => current_user))
    end

    def require_no_user 
      if current_user 
        store_location 
        flash[:error] = "You must be logged out to access that page." 
        redirect_to(root_url)
        return false 
      end 
    end

    def set_default_title
      action = {"index" => "", "new" => "Create ", "edit" => "Edit "}[action_name] || ""
      obj = controller_name.capitalize
      obj = obj.singularize unless action_name == "index"
      @title = action + obj
    end
    
    def store_location  
      session[:return_to] = request.fullpath  
    end
    
    def forget_location
      session[:return_to] = nil
    end
  
    def redirect_back_or_default(default)  
      redirect_to(session[:return_to] || default)  
      forget_location
    end
    
    def mailer_set_url_options
      ActionMailer::Base.default_url_options[:host] = request.host_with_port
    end
end
