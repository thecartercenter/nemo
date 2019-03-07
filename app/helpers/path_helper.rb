module PathHelper
  KEYS = {}

  PLURAL_KEYS = {
    'Sms::Message' => 'sms'
  }

  def dynamic_path(obj_or_class, options = {})
    obj = obj_or_class.is_a?(Class) ? nil : obj_or_class
    klass = obj_or_class.is_a?(Class) ? obj_or_class : obj_or_class.class
    action = options.delete(:action)
    key = KEYS[klass.name] || klass.name.demodulize.underscore
    key = PLURAL_KEYS[klass.name] || key.pluralize if action == :index
    key = "#{action}_#{key}" if [:new, :edit].include?(action)
    key.gsub!("_decorator", "")
    args = [:new, :index].include?(action) ? [options] : [obj, options]
    send("#{key}_path", *args)
  end

  # XXX: it's unclear why Rails is generating a plural helper for
  # :option_set_imports with action :new, but this fixes things...
  def new_option_set_import_path(*args)
    new_option_set_imports_path(*args)
  end
end
