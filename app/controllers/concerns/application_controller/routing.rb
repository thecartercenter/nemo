module Concerns::ApplicationController::Routing
  extend ActiveSupport::Concern

  def default_url_options(options={})
    { :locale => I18n.locale, :mode => params[:mode], :mission_id => current_mission.try(:compact_name) }
  end

  # mailer is for some reason too stupid to figure these out on its own
  def mailer_set_url_options
    # copy options from the above method, and add a host option b/c mailer is especially stupid
    default_url_options.merge(:host => request.host_with_port).each_pair do |k,v|
      ActionMailer::Base.default_url_options[k] = v
    end
  end

  def appropriate_root_path
    current_mission ? mission_root_path(:mode => 'm', :mission_id => current_mission.compact_name) : basic_root_path
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
end