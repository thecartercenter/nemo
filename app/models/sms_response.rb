# TOM this and all other sms-related model classes should be in the sms namespace. please read up on Rails/Ruby namespaces.
class SmsResponse < ActiveRecord::Base
  attr_accessible :message, :response_id
  
  belongs_to :response
  
  validates(:message, :presence => true)
  validates(:response_id, :presence => true)
  	
	# TOM this class needs to be totally redesigned i think. you should not be accessing instance variables in class methods.
	# this is not good object oriented design and indicates something is fundamentally wrong.
	# also definitely need a lot more comments on the methods. each method, especially in an intricate class like this, need good explanations.
	
	def self.message_loaded?(message)
		# sets default message and message var
		# (every reply message contains the text of the original message sent.)
		@outgoing = {:message=>'sms.error.system.general', :vars=>{:message=>message}}
		
		#there arent any errors... yet.
		@noerrors = true
		
		# did the message match the expected format?
		if self.message_decoded? (message)
			
			# if yes get the answers.
			# (we're not saving them yet.)
			self.get_answers
		end	
		
		# if there are errors above, will return false
		return @noerrors
	end
	
	def self.save_answers(sender)
	@sender = sender
		# was a flag added to the message?
		# if it was flagged did the message meet its criteria?
		unless self.is_flagged?
			# save the response
			resp = Response.new(:form => @form, :user => sender, :mission => @mission, 'source' => 'sms', :answers => @answers)			
			resp.save!
			unless resp.new_record?
				
				# set the success message
				@outgoing[:message] = 'sms.success'
				@outgoing[:vars][:report_id] = resp.id
    			
    			# save the sms response
    			sms_resp = create(:message => @message, :response_id => resp.id )
				sms_resp.save!
			else
				@outgoing[:message] = 'sms.error.response.not_valid'
			end
		else
			@outgoing[:message] = 'sms.success'
		end
	end
	
	# TOM returning an instance variable from a class method?
	def self.get_outgoing
		@outgoing	
	end
	
	def self.get_form_id
		@form_id	
	end
	
	def self.get_mission
		@mission
	end
	
	private
	def self.message_decoded? (message)
		result = message.scan(/^(! ?([0-9]+) ([^\-]+[a-z0-9]{1})) ?-?(r)?$/).first				
		
		# did incoming message match regex?
		unless result == nil
			#get the form id
			@form_id = result[1]
			begin	
				@form = Form.find_by_id!(@form_id)
			rescue ActiveRecord::RecordNotFound
				@outgoing[:message] = 'sms.error.form.not_found.'
				@outgoing[:vars][:form_id] = @form_id
				@noerrors = nil
			else
				# no unpublished forms!
				# TOM x == true is equivalent to just x
				if (@form.published == true)
					# extract the mission
					@mission = @form.mission
					
					# how many sms questions are there?
					question_count = SmsCode.where('form_id = ?',@form_id).map(&:questioning).uniq.count
					
					# the entire message except for the flag (-r) if it exists
					@message = result[0]
					# TOM please be consistent with spacing between blocks of code.
					# the code part of the message
					message_code = result[2]
					# the flag 
					@message_flag = result[3]
					
					
					@incoming_codes = message_code.strip.split(' ')
					
					#do the number of responses match the number of questions?
					if(question_count != @incoming_codes.count)
						@outgoing[:message] = 'sms.error.message.no_of_answers'
						@outgoing[:vars][:no_responses] = @incoming_codes.count
						@outgoing[:vars][:no_questions] = question_count

						@noerrors = nil
					end	
					# else there's nothing to be done; everything's good.
					
				else
					@outgoing[:message] = 'sms.error.form.not_avail'
					@outgoing[:vars][:form_id] = @form_id					
					@noerrors = nil
				end
			end	
		else
			@outgoing[:message] = 'sms.error.message.cant_read'
			@noerrors = nil
		end
		return @noerrors
	end
	
	
	def self.get_answers
		# stores all incoming answers - to be saved later
		@answers = []
		
		# for each incoming code (e.g. '1.a')
		@incoming_codes.each { |code|
			# does it match the q_number.response format?
			result = code.scan(/^([0-9]+)\.(.+)?$/).first
			
			# if so..
			unless result == nil
				#question number is in the first part
				incoming_question_number = result[0]
				#answer is in the second part
				incoming_answer = result[1]
				
				# query the SmsCode model for all possible codes
				sms_codes = SmsCode.where('form_id = ? AND question_number = ?', @form_id, incoming_question_number)
				
				# if no, the given question number is not in the db
				if sms_codes.empty?
					@outgoing[:message] = 'sms.error.response.question_not_found.'
					@outgoing[:vars][:question_no] =  incoming_question_number				
					@noerrors = nil
				else
					# as we iterate over each response, @noerrors may have been set previously
					if @noerrors == true	
						
						# what kind of question is this?
						type = sms_codes.first.questioning.question.type.name
						case type
						
						when 'integer'
							# look for a number in the incoming code
							int = incoming_answer.scan(/\A[0-9]+\Z/).first					
							unless int == nil
								self.add_answer(sms_codes.first, int.to_i)
							else
								@outgoing[:message] = 'sms.error.response.NotAnInteger.'
								@outgoing[:vars][:question_no] =  incoming_question_number				
								@outgoing[:vars][:response] =  incoming_answer						
								@noerrors = nil
							end
						
						when 'select_one'
							# search sms_codes for the incoming code 
							answer = sms_codes.select { |c| c.code == incoming_answer}
							
							unless answer == nil
								self.add_answer(answer.first)
							else
								@outgoing[:message] = 'sms.error.response.not_valid_specific.'
								@outgoing[:vars][:question_no] =  incoming_question_number				
								@outgoing[:vars][:response] =  incoming_answer							
								@noerrors = nil
							end
						
						when 'select_multiple'
							choices = []	
							
							#get all of the incoming answers
							answers = incoming_answer.split('')
							
							#add each incoming answer to choices if its avaiable in sms_codes  
							
							answers.each do |a| 
								answer = sms_codes.select { |c| c.code == a}
								unless answer.first == nil
									choices << answer.first.option.id
								else @noerrors == true
									@outgoing[:message] = 'sms.error.response.not_valid_specific.'
									@outgoing[:vars][:question_no] =  incoming_question_number				
									@outgoing[:vars][:response] =  a							
									@noerrors = nil
								end	
							end
							
							unless @noerrors == nil
								# if no errors, add all the choices as an answer
								self.add_answer(answer.first, nil, choices)
							end
						else
							@outgoing[:message] = 'sms.error.system.general'
							@noerrors = nil
						end
					end
				end
	
			else
				@outgoing[:message] = 'sms.error.response.code_not_valid'
				@outgoing[:vars][:code] =  code				
				@noerrors = nil
			end
		}	
		return @noerrors
	end
	
	def self.add_answer(code, value = nil, choices=nil)
		# creates an Answer object in preparation for saving later 
		ans = Answer.new(:relevant=> 'true', :response_id => '', :option_id => (code.option == nil || choices == true ? nil : code.option.id), :questioning_id => code.questioning.id, :value => value )
		unless choices == nil
			# if there are multiple choices, they are added here
			choices.each do |c|
				ans.choices.build(:option_id => c)
			end
		end
		@answers << ans
	end
	
	def self.is_flagged?
		# flag_action = nil => take no action
		flag_action = nil 
		unless @message_flag == nil

			case @message_flag
			when 'r'
				# does the response already exists (and loaded in the last 45 minutes)? 
				sms_response = SmsResponse.find(:all, :conditions => ["responses.user_id = ? AND message = ? AND sms_responses.created_at BETWEEN ? AND ?", @sender.id, @message, Time.now - 45.minutes, Time.now], :joins => {:response =>{}} ).first
				# if so change the flag_action to true
				flag_action = (sms_response == nil ? nil : true)
			end	
		end
		return flag_action
	end
  
end
