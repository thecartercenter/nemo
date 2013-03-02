class Sms::Adapters::IntelliSmsAdapter < Sms::Adapters::Adapter
  require 'open-uri'
  require 'uri'
  
  def service_name
    @service_name ||= "IntelliSMS"
  end
  
  def deliver(message, options = {})
    super
    
    # build the URI the request
    uri = build_uri("sendmsg", "to=#{message.to.join(',')}&text=#{URI.encode(message.body)}")
    
    # honor the dont_send option
    unless options[:dont_send]
      response = send_request(uri)
      
      # get any errors that the service returned
      errors = response.split("\n").reject{|l| !l.match(/ERR:/)}.join("\n")
      raise Sms::Error.new(errors) unless errors.blank?
    end
    
    # if we get to this point, it worked
    return true
  end
  
  # check_balance returns the balance string
  def check_balance
    send_request(build_uri("getbalance")).split(":")[1].to_i
  end
  
  private
    # builds uri based on given action and query string params
    def build_uri(action, params = "") 
      "http://www.intellisoftware.co.uk/smsgateway/#{action}.aspx?" +
        "username=#{configatron.outgoing_sms_username}&password=#{configatron.outgoing_sms_password}&#{params}"
    end
    
    # sends request to given uri and returns response
    def send_request(uri)
      open(uri){|f| f.read}
    end
end