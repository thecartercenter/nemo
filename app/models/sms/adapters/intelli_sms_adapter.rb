require 'open-uri'
require 'uri'
class Sms::Adapters::IntelliSmsAdapter < Sms::Adapters::Adapter
  
  def service_name
    @service_name ||= "IntelliSMS"
  end
  
  def deliver(message)
    # let the superclass do the sanity checks
    super
    
    # build the URI the request
    uri = build_uri(:deliver, :to => message.to.join(','), :text => message.body)
    
    # don't send in test mode
    unless Rails.env == "test"
      response = send_request(uri)
      
      # get any errors that the service returned
      errors = response.split("\n").reject{|l| !l.match(/ERR:/)}.join("\n")
      raise Sms::Error.new(errors) unless errors.blank?
    end
    
    # if we get to this point, it worked
    return true
  end
  
  # we don't currently use intellisms for receiving
  def receive(params)
    raise NotImplementedError
  end
  
  # check_balance returns the balance string
  def check_balance
    send_request(build_uri(:balance)).split(":")[1].to_i
  end
  
  private
    # builds uri based on given action and query string params. returns URI object.
    def build_uri(action, params = {})
      raise Sms::Error.new("no username is configured for the IntelliSms adapter") if configatron.intellisms_username.blank?
      raise Sms::Error.new("no password is configured for the IntelliSms adapter") if configatron.intellisms_password.blank?
    
      page = case action
      when :deliver then "sendmsg"
      when :balance then "getbalance"
      else
        raise ArgumentError.new
      end
      
      # add credentials
      params[:username] = configatron.intellisms_username
      params[:password] = configatron.intellisms_password
    
      uri = URI("http://www.intellisoftware.co.uk/smsgateway/#{page}.aspx")
      uri.query = URI.encode_www_form(params)
      return uri
    end
end