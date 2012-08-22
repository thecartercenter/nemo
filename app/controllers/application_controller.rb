# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class ApplicationController < ActionController::Base
  require 'authlogic'
  include ActionView::Helpers::AssetTagHelper
  
  protect_from_forgery
  rescue_from(Exception, :with => :notify_error)
  before_filter(:set_default_title)
  before_filter(:mailer_set_url_options)
  before_filter(:init_js_array)
  before_filter(:basic_auth_for_xml)
  before_filter(:authorize)
  before_filter(:set_timezone)
  
  helper_method :current_user_session, :current_user, :current_mission, :authorized?
  
  # hackish way of getting the route key identical to what would be returned by model_name.route_key on a model
  def route_key
    self.class.name.underscore.gsub("/", "_").gsub(/_controller$/, "")
  end
  
  protected
    
    # Renders a file with the browser-appropriate MIME type for CSV data.
    # @param [String] filename The filename to render. If not specified, the contents of params[:action] is used.
    def render_csv(filename = nil)
      filename ||= params[:action]
      filename += '.csv'

      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers["Content-type"] = "text/plain" 
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
        headers['Expires'] = "0" 
      else
        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
      end

      render(:layout => false)
    end
    
    # Loads the user-specified timezone from configatron, if one exists.
    def set_timezone
      Time.zone = configatron.timezone.to_s if configatron.timezone
    end
    
    def load_selected_objects(klass)
      params[:selected].keys.collect{|id| klass.find_by_id(id)}.compact
    end
    
    # applies search, permissions, and pagination
    # each of these can be turned off by specifying e.g. :pagination => false in the options array
    def apply_filters(klass, options = {})
      # start relation object
      rel = klass

      # apply search
      @search = Search::Search.new(:class_name => klass.name, :str => params[:search])
      rel = @search.apply(rel) unless options[:search] == false
      
      # apply permissions
      rel = Permission.restrict(rel, :user => current_user, :controller => klass.name.pluralize.underscore, 
        :action => "index") unless options[:permissions] == false

      # apply pagination and return
      rel.paginate(:page => params[:page]) unless options[:pagination] == false
      
      # return the relation
      rel
    end
    
    def init_js_array
      @js = []
      @js << controller_name if File.exists?(File.join(Rails.root, "public/javascripts/custom/#{controller_name}.js"))
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
      # if the request format is XML and there is no user, we should require basic auth
      if request.format == Mime::XML
        @current_user = authenticate_or_request_with_http_basic{|l,p| User.find_by_credentials(l,p)}
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
    
    def current_mission
      current_user ? current_user.current_mission : nil
    end
    
    def authorize
      # make sure user has permissions
      begin
        Permission.authorize(:user => current_user, :mission => current_mission, :controller => route_key, :action => action_name, :request => params)
        return true
      rescue PermissionError
        # if request is for the login page, just go to welcome page with no flash
        if controller_name == "user_sessions" && action_name == "new"
          redirect_to("/")
        # if request is for the logout page, just go to the login page with no flash
        elsif controller_name == "user_sessions" && action_name == "destroy"
          redirect_to(new_user_session_path)
        else
          store_location unless ajax_request?
          # if the user needs to login, send them to the login page
          flash[:error] = $!.to_s
          flash[:error].match(/must login/) ? redirect_to_login : render("permissions/no", :status => :unauthorized)
        end
        # halt the rest of the action
        return false
      end
    end 
    
    def authorized?(params)
      return Permission.authorized?(params.merge(:user => current_user, :mission => current_mission))
    end
    
    # redirects to the login page
    # or if this is an ajax request, returns a 401 unauthorized error
    # in the latter case, the script should catch this error and redirect to the login page itself
    def redirect_to_login
      if ajax_request? 
        flash[:error] = nil
        render(:text => "LOGIN_REQUIRED", :status => 401)
      else
        redirect_to(new_user_session_path)
      end
    end
    
    # don't count automatic timer-based requests for resetting the logout timer
    # all automatic timer-based should set the 'auto' parameter
    def last_request_update_allowed?
      params[:auto].nil?
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
      action = {"index" => "", "new" => "Create ", "create" => "Create ", "edit" => "Edit ", "update" => "Edit "}[action_name] || ""
      obj = controller_name.gsub("_", " ").ucwords
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
    
    def ajax_request?
      request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' || params[:ajax]
    end
end
