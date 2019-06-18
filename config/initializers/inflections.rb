# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(sms)$/i, '\1es')
  inflect.singular(/^(sms)es$/i, '\1')
  inflect.acronym("API")
  inflect.acronym("CSV")

  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
end
