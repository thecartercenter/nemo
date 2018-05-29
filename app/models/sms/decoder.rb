# decodes a coded sms containing an elmo responses
class Sms::Decoder
  # window in which identical message is considered duplicate and discarded
  DUPLICATE_WINDOW = 12.hours
  AUTH_CODE_FORMAT = /[a-z0-9]{4}/i

  # sets up a decoder
  # sms - an Sms::Message object
  def initialize(msg)
    @msg = msg
    @qings_seen = {}
  end

  # main method called to do the decoding
  # returns an unsaved Response object on success
  # raises an Sms::DecodingError on error
  def decode

    # tokenize the message by spaces
    @tokens = @msg.body.split(" ")

    # looks ahead to set the mission based on the form unless the message already has a mission
    set_mission unless @msg.mission.present?

    # attempts to determine whether the message was automated,
    # in which case we do not wish to respond to it
    check_for_automated_sender

    # assigns the user to the message if not already present
    # we do this first because it tells us what language to send errors in (if any)
    find_user

    # Checks to see if this user has sent more messages than permitted within the brute force window
    check_for_brute_force

    # ignore duplicates (we do this after find user so that the reply will be in the right language)
    check_for_duplicate

    # set auth code before fetching form, removing it from the token collection
    set_auth_code

    # try to get form
    find_form

    # check user permissions for form and message mission, if not permitted, error
    authenticate_user
    check_permission

    # create a blank response
    @response = Response.new(user: @user, form: @form, source: "sms", mission: @form.mission)

    # mapping from qing group ID -> answer group
    answer_groups = {}

    parser = Sms::AnswerParser.new(@tokens[1..-1])
    parser.each do |answer|
      qing = find_qing(answer.rank)

      begin
        if qing
          qing_group = qing.parent

          answer_group = answer_groups[qing_group.id]
          if answer_group.nil?
            parent_answer_group = answer_groups[qing_group.parent.try(:id)]
            answer_group = qing_group.build_answer_group(parent_answer_group)
            answer_groups[qing_group.id] = answer_group
          end

          if qing.multilevel?
            answer_set = AnswerSet.new(form_item: qing)
            answer_group.children << answer_set
            answer_group = answer_set
          end

          results = answer.parse(qing)
          results.each do |result|
            answer_group.children << @response.answers.build(result)
          end
        end
      rescue Sms::AnswerParser::ParseError => err
        raise_answer_error(err.type, answer.rank, answer.value, err.params)
      end
    end

    @response.root_node = answer_groups[@form.root_group.id]

    # if we get to this point everything went nicely, so we can return the response
    @response
  rescue Sms::AnswerParser::ParseError => err
    raise_decoding_error(err.type, err.params)
  end

  private
  # attempts to find the form matching the code in the message
  def find_form
    # the form code is the first token
    code = @tokens[0] ? @tokens[0].downcase : ""

    # check that the form code looks right
    raise_decoding_error("invalid_form_code", form_code: code) unless code =~ /\A[a-z]{#{FormVersion::CODE_LENGTH}}\z/

    # attempt to find form version by the given code
    v = FormVersion.find_by_code(code)

    # if version not found, raise error
    raise_decoding_error("form_not_found", form_code: code) unless v

    if @msg.mission
      # if we already know the mission (it may or may not be already stored on the message)
      # and it doesn't match the form's mission, complain
      if v.form.mission != @msg.mission
        raise_decoding_error("form_not_found", form_code: code)
      end
    else
      # If the mission is not stored on the message, set it based on form.
      # This is allowed due to situations where multiple missions may want to use the same phone
      # number or same gateway provider that doesn't support different submit URLs
      # based on incoming phone number.
      @msg.mission = v.form.mission
      @msg.save!
    end

    # if version outdated, raise error
    # here we must specify the form AND form_code since they are different
    raise_decoding_error("form_version_outdated", form: v.form, form_code: code) unless v.is_current?

    # check that form is published
    raise_decoding_error("form_not_published", form: v.form) unless v.form.published?

    # check that form is smsable
    raise_decoding_error("form_not_smsable", form: v.form) unless v.form.smsable?

    # otherwise, we it's cool, store it in the instance, and also store an indexed list of questionings
    @form = v.form
    @questionings = @form.smsable_questionings
  end

  def find_user
    @user = @msg.user
    return if @user.present?

    # get potential users
    possible_users = User.by_phone(@msg.from).active
    return log_authentication_failure unless possible_users.present?

    # check auth code
    auth_code = @tokens.first if @tokens.first =~ AUTH_CODE_FORMAT
    @user = possible_users.find_by(sms_auth_code: auth_code)

    # check assigned to mission
    unless @user.present?
      possible_users = possible_users.assigned_to(@msg.mission)
      @user = possible_users.first if possible_users.count == 1
    end

    # otherwise pick the oldest user
    unless @user.present?
      @user = possible_users.order(created_at: :asc).first
    end

    # save user
    @msg.user = @user
    @msg.save!
  end

  def set_auth_code
    @auth_code = @tokens.shift.downcase if @tokens.first =~ AUTH_CODE_FORMAT
  end

  def set_mission
    form_code = (@tokens.first =~ AUTH_CODE_FORMAT) ? @tokens.second : @tokens.first
    form_version = FormVersion.find_by(code: form_code)
    # if version not found, raise error
    raise_decoding_error("form_not_found", form_code: form_code) unless form_version
    @mission = form_version.mission
    @msg.mission = @mission
    @msg.save!
  end

  def authenticate_user
    if @form.authenticate_sms
      # auth code must be present and match user's auth code
      log_authentication_failure unless (@auth_code.present? && @user.sms_auth_code == @auth_code)
    end
  end

  def log_authentication_failure
    @msg.auth_failed = true
    @msg.save(validate: false)
    raise_decoding_error("user_not_found")
  end

  def check_for_brute_force
    messages = Sms::Message.where(user: @user).since(Sms::BRUTE_FORCE_CHECK_WINDOW.ago).where(auth_failed: true)
    raise_decoding_error("account_locked") if messages.count >= Sms::BRUTE_FORCE_LOCKOUT_THRESHOLD
  end

  def current_ability
    @current_ability ||= Ability.new(user: @user, mission: @msg.mission)
  end

  # checks if the current @user has permission to submit to form @form and
  # the form mission matches the msg mission, raises an error if not
  def check_permission
    raise_decoding_error("form_not_permitted") unless current_ability.can?(:submit_to, @form) &&
        @form.mission == @msg.mission
  end

  # finds the Questioning object specified by the given rank
  # raises an error if no such question exists, or if qing has already been encountered
  def find_qing(rank)
    qing = @questionings[rank]
    raise_decoding_error("question_doesnt_exist", rank: rank) unless qing
    raise_decoding_error("duplicate_answer", rank: rank) if @qings_seen[qing.id]
    @qings_seen[qing.id] = 1
    qing
  end

  # raises an sms decoding error with the given type and includes the form_code if available
  def raise_decoding_error(type, options = {})
    # add in the form and form_code in case they're needed
    if @form
      options[:form] ||= @form
      options[:form_code] ||= @form.current_version.code
    end

    options[:user] ||= @user if @user

    raise Sms::DecodingError.new(type, options)
  end

  # raises an sms decoding error with the given type and includes the current rank and value
  def raise_answer_error(type, rank, value, options = {})
    truncated_value = ActionController::Base.helpers.truncate(value, length: 13)
    raise_decoding_error(type, {rank: rank, value: truncated_value}.merge(options))
  end

  # looks for identical messages within window. raises error if found
  def check_for_duplicate
    # build relation
    rel = Sms::Message.where(from: @msg.from).where(body: @msg.body)

    # if @msg is saved, don't match it!
    rel = rel.where("id != ?", @msg.id) unless @msg.new_record?

    # include the date condition
    rel = rel.where("sent_at > ?", Time.now - DUPLICATE_WINDOW)

    # now we can run the query
    raise_decoding_error("duplicate_submission") if rel.count > 0
  end

  # Checks if sender looks like a shortcode and raises error if so.
  def check_for_automated_sender
    raise_decoding_error("automated_sender") if @msg.from_shortcode?
  end
end
