# handles incoming sms messages from various providers
class SmsController < ApplicationController
  
  # disable csrf protection for this stuff
  protect_from_forgery :except => :create 
  
  def create
    # first we need to figure out which provider sent this message, so we shop it around to all the adapters and see if any recognize it
    handled = false
    Sms::Adapters::Factory.products.each do |klass|
      
      # if we get a match
      if klass.recognize_receive_request?(request)
        
        # go ahead with processing, catching any errors
        begin
          # do the receive
          incomings = klass.new.receive(request)
          
          # store the sms responses in an instance variable so the functional test can access them
          @sms_responses = []
          
          # for each sms, decode it and issue a response (using the outgoing adapter)
          incomings.each do |incoming|
            reply_body = begin
              # decode and get the (ELMO) response
              @elmo_response = Sms::Decoder.new(incoming).decode
              
              # attempt to save it
              @elmo_response.save!
            
              # send congrats!
              t("sms_forms.decoding.congrats", :form_code => @elmo_response.form.current_version.code)
            
            # if there is a decoding error, respond accordingly
            rescue Sms::DecodingError
              # if it's a user not found and the from number is a string, don't reply at all, b/c it's probably some robot
              if $!.type == "user_not_found" && incoming.from =~ /[a-z]/i
                nil
              else
                # if this is an answer format error, add an intro to the beginning
                intro = $!.type =~ /^answer_not_/ ? t("sms_forms.decoding.answer_error_intro", $!.params) + " " : ""
                
                # return the intro plus the main message
                intro + t("sms_forms.decoding.#{$!.type}", $!.params)
              end
              
            # if there is a validation error, respond accordingly
            rescue ActiveRecord::RecordInvalid
              # we only need to handle the first error
              field, error_msgs = @elmo_response.errors.messages.first
              error_msg = error_msgs.first
              
              # get the orignal error key by inverting the dictionary
              dict = t("activerecord.errors.models.response")
              key = dict ? dict.invert[error_msg] : nil
              
              case key
              when :missing_answers
                # if it's the missing_answers error, we need to include which answers are missing
                # get the ranks
                ranks = @elmo_response.missing_answers.map(&:rank).sort.join(",")
                
                # pluralize the translation key if appropriate
                key = "sms_forms.validation.missing_answer"
                key += "s" if @elmo_response.missing_answers.size > 1
                
                # translate
                t(key, :ranks => ranks, :form_code => @elmo_response.form.current_version.code)
              
              when :invalid_answers
                # if it's the invalid_answers error, we need to find the first answer that's invalid and report its error
                invalid_answer = @elmo_response.answers.detect(&:errors)
                t("sms_forms.validation.invalid_answer", :rank => invalid_answer.questioning.rank, 
                  :error => invalid_answer.errors.full_messages.join(", "))
                
              end
              

              # if we found the key, now lookup the sms-style message using the same key
              # else just fall back on the old one (this shouldn't happen in practice)
              #key ? t("sms_forms.validation.#{key}") : error_msg

              # if it's the missing_answers error, we need to find the first Answer that's missing
              #if key == :missing_answers
              #  @elmo_response.answers.each do |a|
              #    puts a.errors.inspect && break if a.errors
              #  end
              #end
            end
            
            unless reply_body.nil?
              # build the reply message
              reply = Sms::Message.new(:direction => :outgoing, :to => incoming.from, :body => reply_body)
            
              # add to the array
              @sms_responses << reply
            end
          end
          
          @sms_responses.each{|r| configatron.outgoing_sms_adapter.deliver(r)}
          
          # render something nice for the robot
          render :text => "OK"
          
        # if we get an error, just log it, or re-throw it if in test mode
        rescue Sms::Error
          Rails.env == "test" ? (raise $!) : (Rails.logger.error("SMS Error: #{$!.to_s}"))
        end
        
        # we can now exit the loop
        handled = true
        break
      end
    end
    
    raise Sms::Error.new("No adapters recognized this receive request") unless handled
  end
end
