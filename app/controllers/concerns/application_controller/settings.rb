# frozen_string_literal: true

module ApplicationController::Settings
  extend ActiveSupport::Concern

  # sets the locale based on the locale param (grabbed from the path by the router)
  def set_locale
    set_locale_or_default(params[:locale])
  end

  # sets locale based on passed preferable lang or default
  def set_locale_or_default(pref_lang)
    I18n.locale = pref_lang.blank? ? I18n.default_locale : pref_lang.to_sym
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
  end

  def set_timezone
    Time.zone = current_mission_config.timezone.to_s
  end

  def default_serializer_options
    {root: false}
  end

  # Loads config for current mission, of if in admin mode, loads root config.
  def current_mission_config
    @current_mission_config ||= Setting.for_mission(current_mission)
  end

  def root_config
    @root_config ||= Setting.root
  end
end
