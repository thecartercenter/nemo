class IntelliSmsAdapter
  require 'open-uri'
  require 'uri'
  
  def self.deliver(numbers, msg)
    raise "No numbers given" if numbers.empty?
    uri = "http://www.intellisoftware.co.uk/smsgateway/sendmsg.aspx?" + 
      "username=#{configatron.intellisms_username}" + 
      "&password=#{configatron.intellisms_password}" + 
      "&to=#{numbers.join(',')}&text=#{URI.encode(msg)}"
    result = open(uri){|f| f.read}
    errors = result.split("\n").reject{|l| !l.match(/ERR:/)}.join("\n")
    raise errors unless errors.blank?
  end
end