class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(Exception, :with => :notify_error)
  before_filter(:set_default_title)
  before_filter(:mailer_set_url_options)
  before_filter(:init_js_array)
  before_filter(:basic_auth_for_xml)
  before_filter(:authorize)
  
  helper_method :current_user_session, :current_user, :authorized?
require 'authlogic'
  protected
    def init_js_array
      @js = []
    end
    
    def notify_error(exception)
      if Rails.env == "production"
        send_error_alert(exception) rescue logger.error($!)
      end
      # still show error page
      raise exception
    end
    
    def send_error_alert(exception)
      AdminMailer.error(exception, session.to_hash, params, request.env).deliver
    end
    
    def basic_auth_for_xml
      Rails.logger.debug(request.authorization)
      # if the request format is XML and there is no user, we should require basic auth
      if request.format == Mime::XML && !current_user
        user = authenticate_or_request_with_http_basic{|l,p| User.find_by_credentials(l,p)}
        @current_user = user if user
      end
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
        if flash[:error].match(/must login/) 
          redirect_to(new_user_session_path)
        else
          render("permissions/no", :status => :unauthorized)
        end
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
