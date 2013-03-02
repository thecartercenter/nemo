class Sms::Adapters::SMSSYNCAdapter < Sms::Adapters::Adapter
  require 'open-uri'
  require 'uri'
 
  def initialize
  	  @incoming_messages = []
  	  @outgoing_messages = []
  end
  
  def service_name
    "SMSSYNC"
  end
  
  def receive (params)						
		# we can't do anything with @secret yet (configatron not loaded)
		# the adapter will test the secret in get_reply			
		@secret = params[:secret]
		m = {
			:phone => params[:from],
			:message => params['message']
			}
		@incoming_messages << m
		return @incoming_messages
	end
	# smssync does not work as a broadcast service!
	def deliver(message, options = {})
	super		
		return nil
	end
	
	def get_reply			
		# this is the standard output for SMSSYNC
		# without this notification, SMSSYNC will 
		# continue to attempt contact with the server
		output = {:payload => {:success => 'true'}}	
		
		# here we test the secret provided by SmsSync 
		# as well as test if outgoing messages are empty
		# and then add outgoing messages
		unless @outgoing_messages.empty? || @secret != configatron.outgoing_sms_extra
			output[:payload][:task] = 'send'
			output[:payload][:messsages] = @outgoing_messages			
		end
		 {:json => output}
	end
	
	def add_outgoing_message (message, phone)
		m = {:message => message, :to => phone}
		@outgoing_messages << m
	end
  
end