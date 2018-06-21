# models a generic sms adapter. should be subclassed.
require "net/http"
class Sms::Adapters::Adapter

  attr_writer :deliveries
  attr_reader :config

  # checks if this adapter recognizes an incoming http receive request
  def self.recognize_receive_request?(request)
    false
  end

  # Whether this adapter can deliver outgoing messages.
  def self.can_deliver?
    raise NotImplementedError
  end

  # Service name is just the descendant class name minus the modules and Adapter suffix.
  def self.service_name
    # Warning: don't memoize this or a bunch of things fail.
    name.split("::").last.gsub(/Adapter$/, "")
  end

  def initialize(options = {})
    @config = options[:config]
  end

  def service_name
    self.class.service_name
  end

  # Saves the message to the DB. Raises an error if no recipients or message empty. Adds adapter name.
  def prepare_message_for_delivery(message)
    # apply the adapter name to the message
    message.adapter_name = service_name

    # error if no recipients or message empty
    raise Sms::Error.new("message has no recipients") if message.recipient_numbers.all?(&:blank?)
    raise Sms::Error.new("message body is empty") if message.body.blank?

    # save the message now, which sets the sent_at
    message.save!

    deliveries << message
  end

  def deliver(message)
    raise NotImplementedError
  end

  # receives one sms messages
  # returns an Sms::Message object
  def receive(request)
    raise NotImplementedError
  end

  # Validates the authenticity of the request (if supported). If not supported, should do nothing.
  def validate(request)
    raise NotImplementedError
  end

  # How replies should be sent. Should be implemented by subclasses.
  def reply_style
    raise NotImplementedError
  end

  # The format to be rendered when responding to an incoming message request.
  def response_format
    :plain
  end

  # The body to be rendered when responding to an incoming message request.
  def response_body(reply)
  end

  def deliveries
    @deliveries ||= []
  end

  protected

  # sends request to given uri, handles errors, or returns response text if success
  def send_request(uri, method = :get, payload = {})
    # create http handler
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 30 # in seconds
    http.read_timeout = 30 # in seconds
    http.use_ssl = true if uri.scheme == "https"


    # create request
    case method
    when :get
      request = Net::HTTP::Get.new(uri.request_uri)
    when :post # only used for FrontlineCloud
      request = Net::HTTP::Post.new(uri.request_uri, initheader = { "Content-Type" => "application/json" })
      request.body = payload.to_json
    end

    # Don't want to actually send HTTP request in test mode.
    return "" if Rails.env.test?

    # send request and catch errors
    begin
      response = http.request(request)
    rescue Timeout::Error
      raise Sms::Error.new("error contacting #{service_name} (timeout)")
    rescue
      raise Sms::Error.new("error contacting #{service_name} (#{$!.class.name}: #{$!.to_s})")
    end

    # return body if it's a clean success, else error
    if response.is_a?(Net::HTTPSuccess)
      return response.body
    else
      raise Sms::Error.new("error contacting #{service_name} (#{response.class.name})")
    end
  end
end
