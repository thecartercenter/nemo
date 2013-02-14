# models an sms message, either incoming or outgoing
# gets created by adapters when messages are incoming
# and gets created by controllers and sent to adapters for sending when messages are outgoing
#
# direction   :incoming or :outgoing
# to          an array of strings holding phone numbers in ITU E.123 format (e.g. ["+14445556666", "+14445556667"])
#             can be nil in case of an incoming message
# from        a string holding a single phone number. can be nil in case of an outgoing message.
# body        a string holding the body of the message
class Sms::Message
  attr_accessor :direction, :to, :from, :body
  
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    raise ArgumentError.new("An SMS message must have a direction") unless direction
  end
end