module PathHelper
  KEYS = {}

  PLURAL_KEYS = {
    'Sms::Message' => 'sms'
  }

  # Tries to get a path for the given object, returns nil if object doesn't have route
  # Preserves the search param in the current query string, if any, unless there was a search error.
  def path_for_with_search(obj)
    begin
      polymorphic_path(obj, @search_error ? {} : {search: params[:search]})
    rescue
      nil
    end
  end

  def dynamic_path(obj_or_class, options = {})
    obj = obj_or_class.is_a?(Class) ? nil : obj_or_class
    klass = obj_or_class.is_a?(Class) ? obj_or_class : obj_or_class.class
    action = options.delete(:action)
    key = KEYS[klass.name] || klass.name.demodulize.underscore
    key = PLURAL_KEYS[klass.name] || key.pluralize if action == :index
    key = "#{action}_#{key}" if [:new, :edit].include?(action)
    args = [:new, :index].include?(action) ? [options] : [obj, options]
    send("#{key}_path", *args)
  end
end
