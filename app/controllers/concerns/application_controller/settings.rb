module Concerns::ApplicationController::Settings
  extend ActiveSupport::Concern

  # sets the locale based on the locale param (grabbed from the path by the router)
  def set_locale
    set_locale_or_default(params[:locale])
  end

  # sets locale based on passed preferable lang or default
  def set_locale_or_default(pref_lang)
    pref_lang_sym = pref_lang.blank? ? I18n.default_locale : pref_lang.to_sym
    I18n.locale = configatron.full_locales.include?(pref_lang_sym) ? pref_lang_sym : I18n.default_locale
  end

  # Loads the user-specified timezone from configatron, if one exists
  def set_timezone
    Time.zone = configatron.timezone.to_s if configatron.timezone?
  end

  # loads settings for the mission, or no mission (admin mode), into configatron
  def load_settings_for_mission_into_config
    @setting = Setting.load_for_mission(current_mission)
  end
end