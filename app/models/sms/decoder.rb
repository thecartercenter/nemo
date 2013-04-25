# decodes a coded sms containing an elmo responses
class Sms::Decoder
  # sets up a decoder
  # sms - an Sms::Message object
  def initialize(msg)
    @msg = msg
  end
  
  # main method called to do the decoding
  # returns an unsaved Response object on success
  # raises an Sms::DecodingError on error
  def decode
    
    # try to get user
    find_user
    
    # tokenize the message by spaces
    @tokens = @msg.body.split(" ")
    
    # try to get form
    find_form
    
    # check user permissions for form, if not permitted, error
    check_permission
    
    # create a blank response
    @response = Response.new(:user => @user, :form => @form, :source => "sms", :mission => @form.mission)
    
    # decode each token after the first
    @tokens[1..-1].each do |tok|
      # if this looks like a regular answer token, treat it as such
      if tok =~ /^(\d+)\.(.*)$/
        # save the rank and values to temporary variables for a moment
        r = $1.to_i
        v = $2
        
        # if the lookahead flag is set, we are now done grabbing tokens for the last tinytext, 
        # so we need to add the answer before proceeding (this also resets the flag)
        add_answer if @lookahead
        
        # now we can assign these instance variables
        @rank = r
        @value = v
        
        # look up the questioning object for the specified rank
        find_qing
        
        # if the question type is lookaheadable, we need to keep grabbing tokens until we hit another answer
        # otherwise just add like normal
        if %w(tiny_text datetime).include?(@qing.question.type.name)
          @lookahead = true
        else
          add_answer
        end
        
      # otherwise, if it's a non-normal chunk but the lookahead flag is set, add it to the value
      elsif @lookahead
        @value = @value.empty? ? tok : @value + " #{tok}"
        
      # otherwise, it's an error
      else
        raise Sms::DecodingError.new("invalid_token", :value => tok)
      end
    end
    
    # if we get to this point and the lookahead flag is still up, add the answer
    add_answer if @lookahead
    
    # if we get to this point everything went nicely, so we can return the response
    return @response
  end
  
  private
    # attempts to find and return the user for the given msg
    # raises an error if not found
    def find_user
      @user = User.where(["phone = ? OR phone2 = ?", @msg.from, @msg.from]).first
      raise Sms::DecodingError.new("user_not_found") unless @user
    end
    
    # attempts to find the form matching the code in the message
    def find_form
      # the form code is the first token
      code = @tokens[0].downcase
      
      # check that the form code looks right
      raise Sms::DecodingError.new("invalid_form_code") unless code.match(/^[a-z]{#{FormVersion::CODE_LENGTH}}$/)
      
      # attempt to find form version by the given code
      v = FormVersion.find_by_code(@tokens[0].downcase)
      
      # if version not found, raise error
      raise Sms::DecodingError.new("form_not_found") unless v
      
      # if version outdated, raise error
      raise Sms::DecodingError.new("form_version_outdated") unless v.is_current?
      
      # check that form is published
      raise Sms::DecodingError.new("form_not_published") unless v.form.published?

      # check that form is smsable
      raise Sms::DecodingError.new("form_not_smsable") unless v.form.smsable?
      
      # otherwise, we it's cool, store it in the instance, and also store an indexed list of questionings
      @form = v.form
      @questionings = @form.questionings.index_by(&:rank)
    end
    
    # checks if the current @user has permission to submit to form @form, raises an error if not
    def check_permission
      raise Sms::DecodingError.new("form_not_permitted") unless Permission.user_can_submit_to_form(@user, @form)
    end
    
    # finds the Questioning object specified by the current value of @rank
    # raises an error if no such question exists
    def find_qing
      @qing = @questionings[@rank]
      raise Sms::DecodingError.new("question_doesnt_exist", :rank => @rank) unless @qing
    end
    
    # adds the answer contained in @value to the @response for the questioning in @qing
    # raises an error if the answer doesn't make sense
    def add_answer
      case @qing.question.type.name
      when "integer"
        # for integer question, make sure the value looks like a number
        raise_answer_error("answer_not_integer") unless @value =~ /^\d+$/
        
        # add to response
        build_answer(:value => @value)

      when "decimal"
        # for integer question, make sure the value looks like a number
        raise_answer_error("answer_not_decimal") unless @value =~ /^[\d]+(\.[\d]+)?$/
        
        # add to response
        build_answer(:value => @value)

      when "select_one"
        # case insensitive
        @value.downcase!
        
        # make sure the value is a letter(s)
        raise_answer_error("answer_not_option_letter") unless @value =~ /^[a-z]+$/
        
        # convert to number (1-based)
        idx = letters_to_index(@value)
        
        # make sure it makes sense for the option set
        raise_answer_error("answer_not_valid_option") if idx > @qing.question.option_set.options.size
        
        # if we get to here, we're good, so add
        build_answer(:option => @qing.question.option_set.options[idx-1])

      when "select_multiple"
        # case insensitive
        @value.downcase!

        # make sure the value is all letters
        raise_answer_error("answer_not_option_letter_multi") unless @value =~ /^[a-z]+$/
        
        # split and convert each to an index
        idxs = @value.split("").map do |l| 
          idx = letters_to_index(l)

          # make this index makes sense for the option set
          raise_answer_error("answer_not_valid_option_multi", :value => l) if idx > @qing.question.option_set.options.size
          
          idx
        end
        # if we get to here, we're good, so add
        build_answer(:choices => idxs.map{|idx| Choice.new(:option => @qing.question.option_set.options[idx-1])})
      
      when "tiny_text"
        # this one is simple
        build_answer(:value => @value)

      when "date"
        # error if too short (must be at least 8 chars)
        raise_answer_error("answer_not_date", :value => @value) if @value.size < 8
        
        # try to parse date
        begin
          @value = Date.parse(@value)
        rescue ArgumentError
          raise_answer_error("answer_not_date", :value => @value)
        end
        
        # if we get to here, we're good, so add
        build_answer(:date_value => @value)
      
      when "time"
        # error if too long or too short (must be 3 or 4 digits)
        digits = @value.gsub(/[^\d]/, "")
        raise_answer_error("answer_not_time", :value => @value) if digits.size < 3 || digits.size > 4

        # try to parse time
        begin
          # add a colon before the last two digits (if needed) and add UTC so timezone doesn't mess things up
          with_colon = @value.gsub(/(\d{1,2})[\.,]?(\d{2})/){"#{$1}:#{$2}"}
          @value = Time.parse(with_colon + " UTC")
        rescue ArgumentError
          raise_answer_error("answer_not_time", :value => @value)
        end

        # if we get to here, we're good, so add
        build_answer(:time_value => @value)

      when "datetime"
        # error if too long or too short (must be between 9 and 12 digits)
        digits = @value.gsub(/[^\d]/, "")
        raise_answer_error("answer_not_datetime", :value => @value) if digits.size < 9 || digits.size > 12

        # try to parse datetime
        begin
          # if we have a string of 12 straight digits, leave it alone
          if @value =~ /^\d{12}$/
            to_parse = @value
          else
            # otherwise add a colon before the last two digits of the time (if needed) to help with parsing
            # also replace any .'s or ,'s or ;'s as they don't work so well
            to_parse = @value.gsub(/(\d{1,2})[\.,;]?(\d{2})[a-z\s]*$/){"#{$1}:#{$2}"}
          end
          @value = Time.zone.parse(to_parse)
        rescue ArgumentError
          raise_answer_error("answer_not_time", :value => @value)
        end

        # if we get to here, we're good, so add
        build_answer(:datetime_value => @value)
        
      end
      
      # TODO adding options shouldn't be allowed under form versioning policy
      
      # reset the lookahead flag
      @lookahead = false
    end
    
    # builds an answer object within the response
    def build_answer(attribs)
      @response.answers.build(attribs.merge(:questioning_id => @qing.id))
    end
    
    # raises an sms error with the given type and includes the current rank and value
    def raise_answer_error(type, options = {})
      raise Sms::DecodingError.new(type, {:rank => @rank, :value => @value}.merge(options))
    end
    
    # converts a series of letters to the corresponding index, e.g. a => 1, b => 2, z => 26, aa => 27, etc.
    def letters_to_index(letters)
      sum = 0
      letters.split("").each_with_index do |letter, i|
        sum += (letter.ord - 96) * (26 ** (letters.size - i - 1))
      end
      sum
    end
end