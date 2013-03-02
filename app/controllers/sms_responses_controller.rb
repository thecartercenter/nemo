class SmsResponsesController < ApplicationController
	
	def incoming				
		# set adapter according to provider param.
		@adapter = Sms::Adapters::Factory.new.create(params[:provider])
		
		# return hash with phone number and message
		# may include more than one message, if a batch is delivered from adapter
		# TOM should be using the Message class here, not hashes
		smses = @adapter.receive(params) 

		# set locale based on lng param
		I18n.locale = params[:lng]
		
		# empty messages are returned as empty arrays
		# single message are returned as array of count 1
		smses.each do |sms|
			# looks up user based on phone
			sender_info = User.where('phone = ? || phone2 = ?', sms[:phone], sms[:phone])
			
			# if a user exists
			unless sender_info.empty?
				# if there's only one user with that number
				if sender_info.count == 1
					sender = sender_info.first	
					# need to reset message - if we're looping over a batch
					@message = nil
					
					# did SmsResponse recognize the code format; find the given form; 
					# did number of responses match number of questions?
					# extracts responses
					# TOM why are you using a class method here?
					if SmsResponse.message_loaded?(sms[:message])						
						mission = SmsResponse.get_mission
						if sender.can_access_mission?(mission)
							#saves responses
							# TOM why is this a class method? this is not good object oriented design
							SmsResponse.save_answers(sender)									
						else                                                                                    
							@message = t 'sms.form.permission_denied', :form_id => sms_response.get_form_id, :message => sms[:message]
						end						
					end
				else
					@message = t 'sms.error.system.multiple_users'
									
				end
				# if the message hasn't been set by controller
				# expects there to be a message provided by SmsResponse
				unless @message
					m = SmsResponse.get_outgoing
					@message = t m[:message], m[:vars]
				end
				
				# add message to batch to be returned to sender
				# TOM why not just use deliver? why add a new method and more complexity to the adapter?
				@adapter.add_outgoing_message(@message, sms[:phone])
			
			else
				#  #blank message for non-recognized numbers
			end
		end
		
		# iterate over every outgoing message to be delivered
		@output = @adapter.get_reply

		render @output
  	end
end
