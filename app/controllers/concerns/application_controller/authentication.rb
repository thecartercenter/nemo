module Concerns::ApplicationController::Authentication
  extend ActiveSupport::Concern

  attr_reader :current_user, :current_mission

  # gets the user and mission from the user session if they're not already set
  def get_user
    # if the request format is XML we should use basic auth
    @current_user = if request.format == Mime::XML
      # authenticate with basic
      user = authenticate_with_http_basic do |login, password|
        # use eager loading to optimize things a bit
        User.includes(:assignments).find_by_credentials(login, password)
      end

      # if authentication not successful, fail
      return request_http_basic_authentication if !user

      user
    else
      # get the current user session from authlogic
      user_session = UserSession.find
      user = user_session.nil? ? nil : user_session.user

      # look up the current user from the user session
      # we use a find call to the User class so that we can do eager loading
      User.includes(:assignments).find(user.id) unless user.nil?
    end
  end

  def get_mission
    # if we're in admin mode, the current mission is nil and we need to set the user's current mission to nil also
    if mission_mode? && params[:mission_id].present?
      # Look up the current mission based on the mission_id.
      # This will return 404 immediately if the mission was specified but isn't found.
      # This helps out people typing in the URL (esp. ODK users) by letting them know permission is not an issue.
      @current_mission = Mission.with_compact_name(params[:mission_id])

      # save the current mission in the session so we can remember it if the user goes into admin mode
      session[:last_mission_id] = @current_mission.try(:id)
    else
      @current_mission = nil
    end
  end

  # get the current user's ability. not cached because it's volatile!
  def current_ability
    Ability.new(:user => current_user, :mode => current_mode, :mission => current_mission)
  end

  # Loads missions accessible to the current ability, or [] if no current user, for use in the view.
  def load_accessible_missions
    @accessible_missions = Mission.accessible_by(current_ability, :switch_to)
  end

  # don't count automatic timer-based requests for resetting the logout timer
  # all automatic timer-based should set the 'auto' parameter
  # (This is an override for a method defined by AuthLogic)
  def last_request_update_allowed?
    params[:auto].nil?
  end
end