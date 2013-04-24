# decodes a coded sms containing an elmo responses
class Sms::Decoder
  # sets up a decoder
  # sms - an Sms::Message object
  def initialize(msg)
    @msg = msg
  end
  
  # main method called to do the decoding
  # returns an unsaved Response object on success
  # raises an Sms::Error on error
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
      if tok =~ /^(\d+)\.(.+)$/
        @rank = $1.to_i
        @value = $2
        
        # look up the questioning object for the specified rank
        find_qing
        
        if @qing.question.type.name == "tiny_text"
          @lookahead = true
        else
          add_answer
        end
      elsif @lookahead
        @value += " #{tok}"
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
      raise Sms::Error.new("user_not_found") unless @user
    end
    
    # attempts to find the form matching the code in the message
    def find_form
      # the form code is the first token
      code = @tokens[0].downcase
      
      # check that the form code looks right
      raise Sms::Error.new("invalid_form_code") unless code.match(/^[a-z]{#{FormVersion::CODE_LENGTH}}$/)
      
      # attempt to find form version by the given code
      v = FormVersion.find_by_code(@tokens[0].downcase)
      
      # if version not found, raise error
      raise Sms::Error.new("form_not_found") unless v
      
      # if version outdated, raise error
      raise Sms::Error.new("form_version_outdated") unless v.is_current?
      
      # check that form is published
      raise Sms::Error.new("form_not_published") unless v.form.published?

      # check that form is smsable
      raise Sms::Error.new("form_not_smsable") unless v.form.smsable?
      
      # otherwise, we it's cool, store it in the instance, and also store an indexed list of questionings
      @form = v.form
      @questionings = @form.questionings.index_by(&:rank)
    end
    
    # checks if the current @user has permission to submit to form @form, raises an error if not
    def check_permission
      raise Sms::Error.new("form_not_permitted") unless Permission.user_can_submit_to_form(@user, @form)
    end
    
    # finds the Questioning object specified by the current value of @rank
    # raises an error if no such question exists
    def find_qing
      @qing = @questionings[@rank]
      raise Sms::Error.new("question_doesnt_exist", :rank => @rank) unless @qing
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
      raise Sms::Error.new(type, {:rank => @rank, :value => @value}.merge(options))
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