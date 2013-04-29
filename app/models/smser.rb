class Smser
  
  def self.deliver(recips, which_phone, msg)
    # first ensure we have a valid adapter
    ensure_adapter
    
    # get numbers
    numbers = []
    numbers += recips.collect{|u| u.phone} if %w(main_only both).include?(which_phone)
    numbers += recips.collect{|u| u.phone2} if %w(alternate_only both).include?(which_phone)
    numbers.compact!
    
    # build the sms
    message = Sms::Message.new(:direction => :outgoing, :to => numbers, :body => msg)
    
    # deliver
    configatron.outgoing_sms_adapter.deliver(message)
  end
  
  # check_balance uses the outgoing adapter to retrieve the SMS balance
  def self.check_balance
    # first ensure we have a valid adapter
    ensure_adapter
    
    configatron.outgoing_sms_adapter.check_balance
  end
  
  def self.outgoing_service_name
    # first ensure we have a valid adapter
    ensure_adapter
    
    configatron.outgoing_sms_adapter.service_name
  end
  
  private
    # checks for a valid adapter and raises an error it there is none
    def self.ensure_adapter
      raise Sms::Error.new("There is no valid outgoing SMS adapter. Please check the settings.") unless configatron.outgoing_sms_adapter
    end
end