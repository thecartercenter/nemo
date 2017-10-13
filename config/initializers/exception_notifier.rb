# Include some default data with all notifications
module ExceptionNotifier
  def notify_exception(e, options = {})
    options[:data] ||= {}
    options[:data][:host] = configatron.url.host
    super(e, options)
  end
end
