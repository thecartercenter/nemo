class Permission
  GENERAL = {
    "users#index" => {:group => :logged_in},
    "users#create" => {:min_level => 4},
    "user_sessions#create" => {:group => :logged_out},
    "user_sessions#destroy" => {:group => :logged_in},
    "password_resets#create" => {:group => :logged_out},
    "password_resets#update" => {:group => :logged_out},
    "languages#*" => {:min_level => 4},
    "places#create" => {:min_level => 2},
    "places#update" => {:min_level => 2},
    "places#index" => {:group => :logged_in},
    "places#map" => {:group => :logged_in},
    "places#destroy" => {:min_level => 2},
    "place_lookups#*" => {:min_level => 2},
    "place_lookups#suggest" => {:group => :logged_in},
    "searches#*" => {:group => :logged_in},
    "welcome#*" => {:group => :anyone},
    "permissions#no" => {:group => :anyone},
    "forms#index" => {:group => :logged_in},
    "forms#show" => {:group => :logged_in},
    "responses#index" => {:group => :logged_in},
    "responses#create" => {:group => :logged_in},
    "responses#show" => {:min_level => 2},
    "responses#update" => {:min_level => 2},
    "responses#destroy" => {:min_level => 2},
    "settings#index" => {:min_level => 4},
    "settings#update_all" => {:min_level => 4},
    "questionings#*" => {:min_level => 4},
    "questions#*" => {:min_level => 4},
    "options#*" => {:min_level => 4},
    "option_sets#*" => {:min_level => 4}
  }
  SPECIAL = [
    :anyone_can_edit_some_fields_about_herself_but_nobody_can_edit_their_own_role,
    :program_staff_can_delete_anyone_except_herself,
    :observer_can_view_edit_delete_own_responses_if_not_reviewed,
    :observer_cant_change_user_or_reviewed_for_response
  ]
  
  def self.authorized?(params)
    begin
      authorize(params)
      return true
    rescue PermissionError
      return false
    end
  end

  def self.authorize(params)
    parse_params!(params)
    # try special permissions first
    SPECIAL.each{|sc| return if send(sc, params)}
    # try general permissions
    return if check_permission("#{params[:controller]}##{params[:action]}", params[:user])
    return if check_permission("#{params[:controller]}#*", params[:user])
    # if we get this far, it didn't work out
    raise PermissionError.new "You don't have permission to do that."
  end
  
  # returns a string containing any select conditions for a select query
  # the model class must know to include a call to this function when building its query
  def self.select_conditions(params)
    parse_params!(params)
    # observer can only see his/her own responses
    if params[:key] == "responses#index" && params[:user].is_observer?
      "responses.user_id = #{params[:user].id}"
    else
      "1"
    end
  end
  
  # checks a general permission. 
  # raises an error (immediate failure) if a matching permission is found and fails
  # returns true if succeeds.
  # returns false if no matching permission is found
  def self.check_permission(key, user)
    Rails.logger.debug("Checking general permission #{key} for #{user ? user.login : 'no user'}")
    # fail if it doesn't exist
    return false unless perm = GENERAL[key]
    # check the various kinds of permission
    if perm[:group]
      if perm[:group] == :anyone
        return true
      elsif perm[:group] == :logged_in
        user ? (return true) : (raise PermissionError.new "You must login to view that page.")
      elsif perm[:group] == :logged_out
        user ? (raise PermissionError.new "You must be logged out to view that page.") : (return true)
      end
    elsif perm[:min_level]
      if !user
        raise PermissionError.new "You must login to view that page." 
      elsif user.role.level < perm[:min_level]
        raise PermissionError.new "You don't have enough permissions to view that page."
      else
        return true
      end
    end
    # if we get this far, we don't know how to process the permission, so we had better fail
    raise PermissionError.new "Error processing permission."
  end
  
  private
    ###############################################
    # SPECIAL PERMISSION FUNCTIONS
    # return true (causing immediate success) if they succeed
    # return false/nil if they fail
    def self.anyone_can_edit_some_fields_about_herself_but_nobody_can_edit_their_own_role(params)
      # this special permission only valid for users#update
      return false unless params[:key] == "users#update"
      # require a user
      return false unless params[:user]
      # get the user object being edited, if the :id param is provided
      params[:object] = User.find_by_id(params[:request][:id]) if params[:request]
      # if this is a program staff
      if params[:user].is_program_staff?
        # if they're not editing themselves, OR if they're not trying to change their own role or active status, they're ok
        return params[:user] != params[:object] || !trying_to_change?(params, 'role', 'role_id', 'active?', 'active')
      # otherwise, they're not a program staff
      else
        # so object and user must be equal to proceed any further
        return false unless params[:user] == params[:object]
        # if they're not trying to change prohibited fields, they're good
        return !trying_to_change?(params, 'first_name', 'last_name', 'active?', 'active', 'role', 'role_id')
      end
    end
  
    def self.program_staff_can_delete_anyone_except_herself(params)
      # this special permission only valid for users#destroy
      return false unless params[:key] == "users#destroy"
      # require a program staff
      return false unless params[:user] && params[:user].is_program_staff?
      # get the user object being edited, if the :id param is provided
      params[:object] = User.find_by_id(params[:request][:id]) if params[:request]
      # if she's not deleting herself, she's ok
      return params[:user] != params[:object]
    end

    def self.observer_can_view_edit_delete_own_responses_if_not_reviewed(params)
      # only valid for responses#update and responses#destroy
      return false unless %w(responses#update responses#destroy responses#show).include?(params[:key])
      # only valid for observers
      return false unless params[:user] && params[:user].is_observer?
      # get the response object being edited
      params[:object] = Response.find_by_id(params[:request][:id]) if params[:request]
      # require an object
      return false unless params[:object]
      # make sure they're not trying to change user or reviewed
      observer_cant_change_user_or_reviewed_for_response(params)
      # make sure the object belongs to the observer 
      # AND, if update or destroy, the response hasn't been reviewed
      return params[:object].user_id == params[:user].id &&
        (params[:key] == "responses#show" || !params[:object].reviewed?)
    end
    
    def self.observer_cant_change_user_or_reviewed_for_response(params)
      # raise exception if user is an observer AND object is a response AND trying to change user_id
      if params[:user] && params[:user].is_observer? && 
        params[:object] && params[:object].is_a?(Response) &&
        trying_to_change?(params, 'user_id', 'user', 'reviewed', 'reviewed?')
        raise PermissionError.new "Observers can't change the submitter for responses."
      end
    end
    
    ###############################################
    # OTHER FUNCTIONS
    # returns true if the user is trying to change any of the given fields, according to the given parameters
    def self.trying_to_change?(params, *fields)
      return params[:col] && fields.include?(params[:col].to_s) ||
         params[:request] && params[:request][:user] && !(fields & params[:request][:user].keys).empty?
    end
    
    def self.parse_params!(params)
      # parse the args
      params[:controller], params[:action] = params[:action].split("#") if params[:action].match(/#/)

      # replace edit/new with update/create
      params[:action] = {"edit" => "update", "new" => "create"}[params[:action]] || params[:action]
      
      # create a shortcut for controller and action
      params[:key] = "#{params[:controller]}##{params[:action]}"
    end
end
