class SmsResponsesController < ApplicationController
	
	def incoming				
	  # TOM space after #. please fix all of these, there are a lot of them.
		#set adapter according to provider param.
		@adapter = Sms::Adapters::Factory.new.create(params[:provider])
		
		# return hash with phone number and message
		# may include more than one message, 
		# if a batch is delivered from adapter
		# TOM should be using the Message class here, not hashes
		smses = @adapter.receive(params) 


    # TOM extra line break?
		#set locale based on lng param
		I18n.locale = params[:lng]

		# TOM if the adapter just returns one message, this will fail
		smses.each do |sms|
		# TOM indentation
		# looks up user based on phone
			sender_info = User.where('phone = ? || phone2 = ?', sms[:phone], sms[:phone])
			
			# if a user exists
			unless sender_info.empty?
				# if there's only one user with that number
				if sender_info.count == 1
					sender = sender_info.first	
					#need to reset message - if we're looping over a batch
					@message = nil
					
					# did SmsResponse recognize the code format; find the given form; 
					# did number of responses match number of questions?
					# extracts responses
					# TOM why are you using a class method here?
					if SmsResponse.message_loaded?(sms[:message])
						
						mission = SmsResponse.get_mission
						# sets configs for given mission
						# TOM you shouldn't need to call this. settings will already be loaded into configatron
						Setting.find_or_create(mission)
						
						if sender.can_access_mission?(mission)
							#saves responses
							# TOM why is this a class method? this is not good object oriented design
							SmsResponse.save_answers(sender)									
						else                                                                                    # TOM spacing. please fix all of these.
							@message = t 'sms.form.permission_denied', :form_id => sms_response.get_form_id, :message=>sms[:message]
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
		# TOM don't need ()
		@output = @adapter.get_reply()
		
		# TOM why are you rendering these if they're already delivered?
		# TOM also no need to worry about other formats. just use whatever you need now.
		# output could be in xml, json (depending on future adapters) in addition to txt, html 
		# those templates not added yet!!!
		render :template => "sms_responses/ok.#{@output[:format]}", :layout => false
  	end
end
