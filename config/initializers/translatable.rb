Translatable.default_options = {locales: -> {
  configatron.has_key?(:preferred_locales) ? configatron.preferred_locales : nil
}}
