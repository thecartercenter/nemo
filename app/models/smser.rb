class Smser
  def self.deliver(recips, which_phone, msg)
    # get adapter from settings
    adapter = configatron.outgoing_sms_adapter
    
    # get numbers
    numbers = []
    numbers += recips.collect{|u| u.phone} if %w(main_only both).include?(which_phone)
    numbers += recips.collect{|u| u.phone2} if %w(alternate_only both).include?(which_phone)
    numbers.compact!
    
    # deliver
    adapter.deliver(numbers, msg)
  end
end