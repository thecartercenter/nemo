# frozen_string_literal: true

module PathHelper
  KEYS = {"OptionSets::Import" => "option_set_import", "Questions::Import" => "question_import"}.freeze
  PLURAL_KEYS = {"Sms::Message" => "sms"}.freeze

  # DEPRECATED: Prefer using path helpers directly in decorators. The below is too complex.
  def dynamic_path(obj_or_class, options = {})
    obj = obj_or_class.is_a?(Class) ? nil : obj_or_class
    klass = obj_or_class.is_a?(Class) ? obj_or_class : obj_or_class.class
    action = options.delete(:action)
    key = KEYS[klass.name] || klass.name.demodulize.underscore
    key = PLURAL_KEYS[klass.name] || key.pluralize if action == :index
    key = "#{action}_#{key}" if %i[new edit].include?(action)
    key = key.gsub("_decorator", "")
    args = %i[new index].include?(action) ? [options] : [obj, options]
    send("#{key}_path", *args)
  end
end
