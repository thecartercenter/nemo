# frozen_string_literal: true

module Sms
  module Decoder
    # Decodes a coded sms containing an elmo responses.
    class Decoder
      # window in which identical message is considered duplicate and discarded
      DUPLICATE_WINDOW = 12.hours
      AUTH_CODE_FORMAT = /[a-z0-9]{4}/i.freeze

      attr_accessor :response, :decoding_succeeded

      alias decoding_succeeded? decoding_succeeded

      delegate :form, to: :response

      # sets up a decoder
      # sms - an Sms::Message object
      def initialize(msg)
        @msg = msg
        @qings_seen = {}
      end

      # Main method called to do the decoding
      # raises an Sms::Decoder::DecodingError on error
      # Builds an unsaved response accessible via `response` accessor.
      def decode
        # tokenize the message by spaces
        @tokens = @msg.body.split(" ")

        # Attempts to determine whether the message was automated, in which case we do not wish to
        # respond to it. We can do this before setting the mission/locale because it won't generate a reply.
        check_for_automated_sender

        # Looks ahead to set the mission based on the form unless the message already has a mission
        # We do this early on because the mission will be used to determine the locale in which to reply.
        set_mission if @msg.mission.blank?

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

        self.response = Response.new(user: @user, form: @form, source: "sms", mission: @form.mission)
        tree_builder = Sms::ResponseTreeBuilder.new(response)
        answers = []

        pairs = Sms::Decoder::AnswerParser.new(@tokens[1..])
        pairs.each do |pair|
          next unless (qing = find_qing(pair.rank))

          begin
            pair.qing = qing
            parent = tree_builder.build_or_find_parent_node_for_qing(qing)
            pair.parse.each do |attribs|
              answers << tree_builder.add_answer(parent, attribs)
            end
          rescue Sms::Decoder::ParseError => e
            raise_answer_error(e.type, pair.rank, pair.value, e.params)
          end
        end

        answers_by_qing = answers.index_by(&:questioning_id)
        missing_answers = qings.select do |q|
          q.required? && q.visible? && answers_by_qing[q.id].nil?
        end
        raise_decoding_error("missing_answers", missing_answers: missing_answers) if missing_answers.any?
        raise_decoding_error("no_answers") unless tree_builder.answers?

        self.decoding_succeeded = true
      rescue Sms::Decoder::ParseError => e
        raise_decoding_error(e.type, e.params)
      end

      # Finalizes the decoding process by persisting the built response.
      def finalize
        return unless decoding_succeeded?

        ActiveRecord::Base.transaction do
          response.root_node._ct_fast_insert!
          response.save(validate: false)
        end
      end

      private

      # attempts to find the form matching the code in the message
      def find_form
        # the form code is the first token
        code = @tokens[0] ? @tokens[0].downcase : ""

        # check that the form code looks right
        unless /\A[a-z]{#{FormVersion::CODE_LENGTH}}\z/.match?(code)
          raise_decoding_error("invalid_form_code", form_code: code)
        end

        # attempt to find form version by the given code
        version = FormVersion.find_by(code: code)

        # if version not found, raise error
        raise_decoding_error("form_not_found", form_code: code) unless version

        form = version.form

        if @msg.mission
          # if we already know the mission (it may or may not be already stored on the message)
          # and it doesn't match the form's mission, complain
          raise_decoding_error("form_not_found", form_code: code) if form.mission != @msg.mission
        else
          # If the mission is not stored on the message, set it based on form.
          # This is allowed due to situations where multiple missions may want to use the same phone
          # number or same gateway provider that doesn't support different submit URLs
          # based on incoming phone number.
          @msg.mission = form.mission
          @msg.save!
        end

        # If form version outdated we must specify the form AND form_code in the error message
        # since they are different.
        if version.number < form.minimum_version_number
          raise_decoding_error("form_version_outdated", form: form, form_code: code)
        end

        raise_decoding_error("form_not_live", form: form) unless form.live?
        raise_decoding_error("form_not_smsable", form: form) unless form.smsable?

        # If we get to here we're good.
        @form = form
        @ranks_to_qings = @form.smsable_questionings
      end

      def find_user
        @user = @msg.user
        return if @user.present?

        # get potential users
        possible_users = User.by_phone(@msg.from).active
        return log_authentication_failure if possible_users.blank?

        # check auth code
        auth_code = @tokens.first if @tokens.first =~ AUTH_CODE_FORMAT
        @user = possible_users.find_by(sms_auth_code: auth_code)

        # check assigned to mission
        if @user.blank?
          possible_users = possible_users.assigned_to(@msg.mission)
          @user = possible_users.first if possible_users.count == 1
        end

        # otherwise pick the oldest user
        @user = possible_users.order(created_at: :asc).first if @user.blank?

        # save user
        @msg.user = @user
        @msg.save!
      end

      def set_auth_code
        @auth_code = @tokens.shift.downcase if @tokens.first =~ AUTH_CODE_FORMAT
      end

      def set_mission
        form_code = AUTH_CODE_FORMAT.match?(@tokens.first) ? @tokens.second : @tokens.first
        form_version = FormVersion.find_by(code: form_code)
        # if version not found, raise error
        raise_decoding_error("form_not_found", form_code: form_code) unless form_version
        @mission = form_version.mission
        @msg.mission = @mission
        @msg.save!
      end

      def authenticate_user
        return unless @form.authenticate_sms
        # auth code must be present and match user's auth code
        log_authentication_failure unless @auth_code.present? && @user.sms_auth_code == @auth_code
      end

      def log_authentication_failure
        @msg.auth_failed = true
        @msg.save(validate: false)
        raise_decoding_error("user_not_found")
      end

      def check_for_brute_force
        messages = Sms::Message
          .where(user: @user)
          .since(Sms::BRUTE_FORCE_CHECK_WINDOW.ago)
          .where(auth_failed: true)
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
        qing = @ranks_to_qings[rank]
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
          options[:form_code] ||= @form.code
        end

        options[:user] ||= @user if @user

        raise Sms::Decoder::DecodingError.new(type, options)
      end

      # raises an sms decoding error with the given type and includes the current rank and value
      def raise_answer_error(type, rank, value, options = {})
        truncated_value = ActionController::Base.helpers.truncate(value, length: 13)
        raise_decoding_error(type, {rank: rank, value: truncated_value}.merge(options))
      end

      # Looks for identical messages within window. Raises error if found.
      def check_for_duplicate
        rel = Sms::Message.where(from: @msg.from).where(body: @msg.body)
        rel = rel.where.not(id: @msg.id) unless @msg.new_record?
        rel = rel.where("sent_at > ?", Time.zone.now - DUPLICATE_WINDOW)
        raise_decoding_error("duplicate_submission") if rel.any?
      end

      # Checks if sender looks like a shortcode and raises error if so.
      def check_for_automated_sender
        raise_decoding_error("automated_sender") if @msg.from_shortcode?
      end

      def qings
        @ranks_to_qings.values
      end
    end
  end
end
