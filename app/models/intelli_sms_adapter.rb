class IntelliSmsAdapter
  require 'open-uri'
  require 'uri'
  
  def self.service_name
    "IntelliSMS"
  end
  
  def self.deliver(numbers, msg)
    raise "No numbers given" if numbers.empty?
    result = make_request("sendmsg", "to=#{numbers.join(',')}&text=#{URI.encode(msg)}")
    errors = result.split("\n").reject{|l| !l.match(/ERR:/)}.join("\n")
    raise errors unless errors.blank?
  end 
  
  # check_balance returns the balance string
  def self.check_balance
    make_request("getbalance").split(":")[1].to_i
  end
  
  private
    # builds uri based on given action and query string params and returns the response
    def self.make_request(action, params = "") 
      uri = "http://www.intellisoftware.co.uk/smsgateway/#{action}.aspx?" +
         "username=#{configatron.intellisms_username}&password=#{configatron.intellisms_password}&#{params}"
      open(uri){|f| f.read}
    end
end