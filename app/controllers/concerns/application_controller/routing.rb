require 'uri'
module Concerns::ApplicationController::Routing
  extend ActiveSupport::Concern

  def check_route
    raise "params[:mission_name] not allowed in #{current_mode} mode" if !mission_mode? && params[:mission_name].present?
  end

  def default_url_options(options={})
    { :locale => I18n.locale, :mode => params[:mode], :mission_name => current_mission.try(:compact_name) }
  end

  # mailer is for some reason too stupid to figure these out on its own
  def mailer_set_url_options
    # copy options from the above method, and add a host option b/c mailer is especially stupid
    default_url_options.merge(:host => request.host_with_port).each_pair do |k,v|
      ActionMailer::Base.default_url_options[k] = v
    end
  end

  def appropriate_root_path
    current_mission ? mission_root_path(:mode => 'm', :mission_name => current_mission.compact_name) : basic_root_path
  end

  def current_mode
    @current_mode ||= case params[:mode]
    when 'admin' then 'admin'
    when 'm' then 'mission'
    else 'basic'
    end
  end

  def admin_mode?
    current_mode == 'admin'
  end

  def mission_mode?
    current_mode == 'mission'
  end

  def basic_mode?
    current_mode == 'basic'
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
      uri.query = uri.query.split('&').reject{|c| c == 'missionchange=1'}.join('&')
      uri.query = nil if uri.query.blank?
      redirect_to(uri.to_s)
    end
  end
end
