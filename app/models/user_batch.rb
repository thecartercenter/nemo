class UserBatch
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_reader :created_users
  attr_accessor :batch, :lines

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def persisted?
    false
  end

  def succeeded?
    !@validation_error
  end

  # creates users based on the data submitted via the users attribute
  def create_users(mission)
    # assume no errors to start with
    @validation_error = false

    # if batch was given, convert to lines
    if !batch.blank?
      self.lines = batch.split("\n").reject{|t| t.strip.blank?}.map{|t| {:text => t}}
    end

    # create the users in a transaction in case of validation error
    User.transaction do

      # iterate over each line, creating users as we go
      lines.each do |line|

        # split the line's text by delimiter, strip whitespace, and remove blanks
        tokens = line[:text].split(/,|\t/).map{|t| t.strip}.reject{|t| t.blank?}

        # iterate over tokens, trying to identify each one
        parsed = {:phones => [], :emails => [], :names => []}
        tokens.each do |t|
          # if it looks like a phone number
          if t =~ /\A\+?[\d\-\.]+\z/
            parsed[:phones] << t
          # if it looks like an email
          elsif t =~ /\A([0-9a-zA-Z]([-\.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})\z/
            parsed[:emails] << t
          # else we assume it's a name
          else
            parsed[:names] << t
          end
        end

        # if there are too many of any token type, that's an error, so add them to the bad token list
        line[:bad_tokens] = []
        line[:bad_tokens] += (parsed[:names][1..-1] || [])
        line[:bad_tokens] += (parsed[:emails][1..-1] || [])
        line[:bad_tokens] += (parsed[:phones][2..-1] || [])

        if line[:bad_tokens].empty?
          # attempt to create the user with the parsed params, and save it with the line
          line[:user] = User.create(:name => parsed[:names][0], :email => parsed[:emails][0],
            :phone => parsed[:phones][0], :phone2 => parsed[:phones][1], :reset_password_method => "print",
            :assignments => [Assignment.new(:mission_id => mission.id, :role => User::ROLES.first)])

          # if the user has errors, set the flag
          @validation_error = true if !line[:user].valid?
        else
          @validation_error = true
        end

      end # iteration over lines

      # now if there was a validation error with any user, rollback the transaction
      raise ActiveRecord::Rollback if @validation_error

    end # transaction

  end
end
