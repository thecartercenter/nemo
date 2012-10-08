class Smser
  
  def self.deliver(recips, which_phone, msg)
    
    # get numbers
    numbers = []
    numbers += recips.collect{|u| u.phone} if %w(main_only both).include?(which_phone)
    numbers += recips.collect{|u| u.phone2} if %w(alternate_only both).include?(which_phone)
    numbers.compact!
    
    # deliver
    configatron.outgoing_sms_adapter.deliver(numbers, msg)
  end
  
  # check_balance uses the Intellisms adapter to retrieve the SMS balance
  def self.check_balance
    configatron.outgoing_sms_adapter.check_balance
  end
  
  def self.outgoing_service_name
    configatron.outgoing_sms_adapter.service_name
  end
end