# models a generic sms adapter. should be subclassed.
class Sms::Adapters::Adapter
  
  # delivers a message to one or more recipients
  # raises an error if no recipients, wrong direction, or message empty
  # should also raise an error if the provider returns an error code
  # returns true if all goes well
  # 
  # message   the message to be sent
  # options   if options[:dont_send] is specified, external communication shouldn't be sent (for testing purposes)
  def deliver(message, options = {})
    # error if no recipients or direction is wrong or message empty
    raise Sms::Error.new("Message has no recipients") if message.to.empty?
    raise Sms::Error.new("Message should have direction :outgoing") if message.direction != :outgoing
    raise Sms::Error.new("Message body is empty") if message.body.empty?
  end
  
  # returns the number of sms credits available in the provider account
  # should be overridden if this feature is available
  def check_balance
    raise NotImplementedError
  end
end