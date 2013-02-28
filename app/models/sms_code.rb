# TOM need more comments in this class. especially on load_sms_code function. explain what this class is modelling.
class SmsCode < ActiveRecord::Base
  attr_accessible :code, :option_id, :form_id, :question_number, :questioning_id

  	belongs_to :questioning
  	belongs_to :option
  
  	validates(:questioning_id, :presence => true)
  	validates(:form_id, :presence => true)
  	validates(:question_number, :presence => true)
  	
  	# TOM not sure about this method name. what is it loading? isn't it more like creating?
  	def self.load_sms_code(qing, nn)
		# TOM nice!
		alpha_index = ('a'..'z').to_a
		
		# are there options for this qing?
		options = (qing.question.option_set == nil ? [] : qing.question.option_set.sorted_options)
    
    # TOM space after #
		#if there are options:
		unless options.empty?
			options.each_with_index do |option, n|
				# create a new sms_code for each option
				                    # TOM space before =>                   TOM fetch? why not just [n]?               TOM please use two lines for long statements
				sms_code = new(:form_id=> qing.form_id, :code => alpha_index.fetch(n), :option_id => option.id, :questioning_id => qing.id, :question_number => nn)
				# use create! instead of new + save!
				sms_code.save!
				
			end
		else
		  # TOM space after #, use create!
			#if there are no options, just save sms_code with option_id = nil and code = nil
			sms_code = new(:form_id=> qing.form_id, :questioning_id => qing.id, :question_number => nn)
			sms_code.save!
		end				
	end
end
