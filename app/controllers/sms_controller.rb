# handles incoming sms messages from various providers
class SmsController < ApplicationController
  
  # disable csrf protection for this stuff
  protect_from_forgery :except => :create 
  
  # takes an incoming sms and returns an outgoing one
  # may return nil if no response is appropriate
  def self.handle_sms(sms)
    reply_body = begin
      # decode and get the (ELMO) response
      @elmo_response = Sms::Decoder.new(sms).decode
      
      # attempt to save it
      @elmo_response.save!
    
      # send congrats!
      I18n.t("sms_forms.decoding.congrats", :form_code => @elmo_response.form.current_version.code)
    
    # if there is a decoding error, respond accordingly
    rescue Sms::DecodingError
      # if it's a user not found and the from number is a string, don't reply at all, b/c it's probably some robot
      if $!.type == "user_not_found" && sms.from =~ /[a-z]/i
        nil
      else
        msg = I18n.t("sms_forms.decoding.#{$!.type}", $!.params)
        
        # if this is an answer format error, add an intro to the beginning and add a period
        if $!.type =~ /^answer_not_/ 
          I18n.t("sms_forms.decoding.answer_error_intro", $!.params) + " " + msg + "."
        else
          msg
        end
      end
      
    # if there is a validation error, respond accordingly
    rescue ActiveRecord::RecordInvalid
      # we only need to handle the first error
      field, error_msgs = @elmo_response.errors.messages.first
      error_msg = error_msgs.first
      
      # get the orignal error key by inverting the dictionary
      dict = I18n.t("activerecord.errors.models.response")
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
        I18n.t(key, :ranks => ranks, :form_code => @elmo_response.form.current_version.code)
      
      when :invalid_answers
        # if it's the invalid_answers error, we need to find the first answer that's invalid and report its error
        invalid_answer = @elmo_response.answers.detect(&:errors)
        I18n.t("sms_forms.validation.invalid_answer", :rank => invalid_answer.questioning.rank, 
          :error => invalid_answer.errors.full_messages.join(", "))
      
      else
        # if we don't recognize the key, just use the regular message. it may not be pretty but it's better than nothing.  
        error_msg
      end
    end
    
    if reply_body.nil?
      return nil
    else
      # build the reply message
      reply = Sms::Message.new(:to => sms.from, :body => reply_body)
    
      # add to the array
      return reply
    end
  end
  
  def create
    # first we need to figure out which provider sent this message, so we shop it around to all the adapters and see if any recognize it
    handled = false
    Sms::Adapters::Factory.products.each do |klass|
      
      # if we get a match
      if klass.recognize_receive_request?(request)
        
        # go ahead with processing, catching any errors
        begin
          # do the receive
          @incomings = klass.new.receive(request)
          
          # for each sms, decode it and issue a response (using the outgoing adapter)
          # store the sms responses in an instance variable so the functional test can access them
          @sms_responses = @incomings.map{|sms| self.class.handle_sms(sms)}.compact
          
          # send the responses
          @sms_responses.each{|r| configatron.outgoing_sms_adapter.deliver(r)}
          
        # if we get an error
        rescue Sms::Error
          # notify the admin (if production) but don't re-raise it so that we can keep processing other msgs
          if Rails.env == "production"
            notify_error($!, :dont_re_raise => true)
          # if not in production, re-raise it
          else
            raise $!
          end
        end
        
        # we can now exit the loop
        handled = true
        break
      end
    end
    
    raise Sms::Error.new("No adapters recognized this receive request") unless handled
    
    # render something nice for the robot
    render :text => "OK"
  end
end
