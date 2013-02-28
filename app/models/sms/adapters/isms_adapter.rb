class Sms::Adapters::ISMSAdapter < Sms::Adapters::Adapter
  require 'open-uri'
  require 'uri'
 
  def initialize
    # TOM don't think you need these. an adapter doesn't model a send/receive session. it is just a conduit for messages to flow through.
  	  @incoming_messages = []
  	  @outgoing_messages = []
  end
  
  def service_name
    "ISMS"
  end

  # receives data in XML from ISMS server when a message is received  
  # TOM should specify clearly here that return value could be an array or a single Message.
  def receive (params)		
                      # TOM be consistent with spaces inside parens. in this project there are usually no spaces.
		hash = Hash.from_xml( params[:XMLDATA] )				
		base = hash['Response']['MessageNotification']
		
		# SMS sometimes sends incoming messages in a batch 
		if base.is_a? Array
		  # TOM please read up on conventional syntax for multi-line ruby blocks. (do...end). there are many of these, please fix all.
			base.each{ |message|
			  # TOM please use the Sms::Message class
			  # it's generally a warning sign if a method is returning hashes that look like they should be objects
				m = {
					:phone => message['SenderNumber'],
					:message => message['Message']
					}
				@incoming_messages << m
			}
		#sometimes as a single message
		else
			m = {
				:phone => base['SenderNumber'],
				:message => base['Message']
				}
			@incoming_messages << m
		end
		return @incoming_messages
		
		# TOM note that you could rewrite all the above like so:
		# Array.wrap(base).collect{|m| Sms::Message.new(:from => m['SenderNumber'], :body => m['Message'])}
	end
	
	def deliver(message, options = {})
	super		
		text = URI.encode(message.body)
		message.to.each{ |n|
			# build the URI the request
			uri = build_uri("sendmsg", "to=#{n}&text=#{text}")			
			# honor the dont_send option
			# TOM please use one-liners for simple conditions like this
			unless options[:dont_send]
			  response = send_request(uri)
			  # no error reporting from isms  
			end
		}
		# if we get to this point, it worked
		return true
	end
	
	# deliver each outgoing message
	# TOM i doubt this method is necessary. see comments in controller.
	def get_reply
		unless @outgoing_messages.empty?
			@outgoing_messages.each{ |m|				
				deliver(m)
			}
		end
		{:output => '', :format=>'txt'}	
	end
	
	# since the system may receive a batch, 
	# with each pass through the sms_response_controller
	# we add an outgoing message and corresponding phone #
	# to the outgoing_messages array
	# TOM ditto here.
	def add_outgoing_message (message, phone)
		m = Sms::Message.new(:direction => :outgoing, :to => [phone], :body => message)
		@outgoing_messages << m
	end
	
	private
    # builds uri based on given action and query string params
    def build_uri(action, params = "")
    	"http://#{configatron.outgoing_sms_extra}/#{action}?" + 
    	"user=#{configatron.outgoing_sms_username}&enc=1&passwd=#{configatron.outgoing_sms_password}&cat=1&#{params}"
      # TOM extra blank line. please try to be tidy.
      
    end
    
    # sends request to given uri and returns response
    def send_request(uri)
       open(uri){|f| f.read}
    end
  
end