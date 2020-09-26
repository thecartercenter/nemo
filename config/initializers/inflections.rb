# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(sms)$/i, '\1es')
  inflect.singular(/^(sms)es$/i, '\1')
  inflect.singular(/^o_data$/i, "o_data")
  inflect.acronym("API")
  inflect.acronym("CSV")
  inflect.acronym("URL")

  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
