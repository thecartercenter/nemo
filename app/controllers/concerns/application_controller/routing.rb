# frozen_string_literal: true

require "uri"
module ApplicationController::Routing
  extend ActiveSupport::Concern

  def check_route
    if !mission_mode? && params[:mission_name].present?
      raise "params[:mission_name] not allowed in #{current_mode} mode"
    end
  end

  def default_url_options(_options = {})
    {locale: I18n.locale, mode: params[:mode], mission_name: current_mission.try(:compact_name)}
  end

  def current_mode
    @current_mode ||=
      case params[:mode]
      when "admin" then "admin"
      when "m" then "mission"
      else "basic"
      end
  end

  def admin_mode?
    current_mode == "admin"
  end

  def mission_mode?
    current_mode == "mission"
  end

  def basic_mode?
    current_mode == "basic"
  end

  def current_root_path
    send("#{current_mode}_root_path")
  end

  # The missionchange param is set so that permission errors on mission change can be handled gracefully.
  # But it should be removed once it is no longer needed so that the user never sees it.
  # Implicit in this method is that missionchange will only ever appear with GET request URLs.
  def remove_missionchange_flag
    if params[:missionchange]
      # This method runs before authorization is performed, so we don't know whether the path to which we
      # are about to redirect will give rise to an authorization error. So we save the missionchange param
      # in the flash so that in the event of an error, we will know that it came from a mission change.
      flash[:missionchange] = true

      uri = URI.parse(request.fullpath)
      uri.query = uri.query.split("&").reject { |c| c == "missionchange=1" }.join("&")
      uri.query = nil if uri.query.blank?
      redirect_to(uri.to_s)
    end
  end

  # The path to which the user should be directed if exiting admin mode.
  def admin_mode_exit_path
    current_user.best_mission ?
      mission_root_path(mission_name: current_user.best_mission.compact_name) :
      basic_root_path
  end

  # Saves the current mission (or lack thereof) to the DB.
  def remember_mission
    current_user.remember_last_mission(current_mission) if current_user && current_mode == "mission"
  end
end
