# frozen_string_literal: true

# By default, we only want to allow locales in the configatron.preferred_locales
# array to be used. Otherwise we can end up displaying translations hanging around in the DB
# from languages that have since been removed from the mission.
configatron.translatable.default_options = {locales: lambda {
  configatron.key?(:preferred_locales) ? configatron.preferred_locales : nil
}}
