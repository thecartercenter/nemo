# frozen_string_literal: true

# Application Controller
class ApplicationController < ActionController::Base
  require "authlogic"
  include ActionView::Helpers::AssetTagHelper

  include ApplicationController::Authentication
  include ApplicationController::Authorization
  include ApplicationController::Caching
  include ApplicationController::Crud
  include ApplicationController::ErrorHandling
  include ApplicationController::LoginLogistics
  include ApplicationController::Monitoring
  include ApplicationController::Reflection
  include ApplicationController::Routing
  include ApplicationController::Settings

  # Makes sure authorization is performed in each controller. (CanCan method)
  check_authorization

  protect_from_forgery with: :exception, unless: -> { request.format.json? || request.format.xml? }

  rescue_from CanCan::AccessDenied, with: :handle_access_denied
  rescue_from RecentLoginRequiredError, with: :handle_recent_login_required
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_authenticity_token

  before_action :set_initial_exception_context
  before_action :disable_client_caching
  before_action :check_route
  before_action :remove_missionchange_flag
  before_action :set_locale
  before_action :load_current_mission
  before_action :load_current_user
  before_action :prepare_exception_notifier
  before_action :protect_admin_mode
  before_action :remember_mission
  before_action :remember_context, only: :index
  before_action :set_scout_context
  before_action :load_settings_for_mission_into_config
  before_action :load_accessible_missions

  helper_method :current_mode, :current_user, :current_mission, :current_root_path,
    :admin_mode?, :basic_mode?, :mission_mode?, :admin_mode_exit_path, :offline_mode?, :offline?
end
