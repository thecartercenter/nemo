# models an sms message, either incoming or outgoing
# gets created by adapters when messages are incoming
# and gets created by controllers and sent to adapters for sending when messages are outgoing
#
# direction   :incoming or :outgoing
# to          a string or an array of strings holding phone numbers in ITU E.123 format (e.g. ["+14445556666", "+14445556667"])
#             can be nil in case of an incoming message
# from        a string holding a single phone number. can be nil in case of an outgoing message.
# body        a string holding the body of the message
class Sms::Message
  attr_accessor :direction, :to, :from, :body
  
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    
    # check for direction attrib
    raise ArgumentError.new("An SMS message must have a direction") unless direction
    
    # arrayify to if necessary
    self.to = Array.wrap(to)
    
    # normalize phone numbers if not in ITU E.123 format
    self.from = normalize_phone(from)
    to.each_with_index do |phone, i|
      self.to[i] = normalize_phone(phone)
    end
  end
  
  private
    # remove all non-digit chars and add a plus at the front 
    # (unless the number looks like a text string (has letters), in which case we leave it alone)
    def normalize_phone(phone)
      phone.nil? ? nil : (phone =~ /[a-z]/i ? phone : ("+" + phone.gsub(/[^\d]/, "")))
    end
end