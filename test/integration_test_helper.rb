require 'test_helper'

class ActionController::TestCase

  setup :set_url_options

  def set_url_options
    puts "IN HERE"
    default_url_options[:locale] = I18n.locale
    default_url_options[:mode] = 'm'
    default_url_options[:mission_id] = 'missionwithsettings'
  end

  # def process_with_default_locale(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
  #   parameters = {:locale=>'en'}.merge(parameters||{})
  #   process_without_default_locale(action, parameters, session, flash, http_method)
  # end
  # alias_method_chain :process, :default_locale

end