require 'open-uri'
require 'uri'
class Sms::Adapters::IntelliSmsAdapter < Sms::Adapters::Adapter

  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(params)
    # if the params from, text, msgid, and sent are all in the request params, its ours!
    %w(from text msgid sent) - params.keys == []
  end

  def self.can_deliver?
    true
  end

  def deliver(message)
    prepare_message_for_delivery(message)

    # encode the message (intellisms expects iso-8859-1 encoding)
    body = message.body.encode("iso-8859-1", {:invalid => :replace, :undef => :replace, :replace => '?'})

    # build the URI the request
    params = {:to => message.recipient_numbers.join(','), :text => body}

    # include the from number if it is set
    params[:from] = message.from.gsub(/^\+/, "") if message.from

    uri = build_uri(:deliver, params)
    Rails.logger.info("Sending IntelliSMS request: #{uri}")

    response = send_request(uri)
    parse_and_raise_any_errors(response)

    # if we get to this point, it worked
    return true
  end

  def receive(params)
    # strip leading zeroes from the from number (intellisms pads the country code with 0s)
    params['from'].gsub!(/^0+/, "")

    # create and return the message
    Sms::Incoming.create(
      :from => "+#{params['from']}",
      :to => configatron.incoming_sms_number, # Assume it's this since IntelliSms doesn't provide it.
      :body => params['text'],
      :sent_at => Time.parse(params['sent']),
      :adapter_name => service_name)
  end

  # Check_balance returns the balance string. Raises error if balance check failed.
  def check_balance
    response = send_request(build_uri(:balance))
    response.match(/^BALANCE:(\d+)\s*$/) ? $1.to_i : parse_and_raise_any_errors(response)
  end

  # How replies should be sent.
  def reply_style
    :via_adapter
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

    def parse_and_raise_any_errors(response)
      # get any errors that the service returned
      errors = response.split("\n").reject{|l| !l.match(/ERR:/)}.join("\n")
      raise Sms::Error.new("IntelliSMS Server Error: #{errors}") unless errors.blank?
    end
end
