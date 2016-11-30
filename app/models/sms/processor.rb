# Takes an incoming Sms::Message and returns a translated and formatted reply and/or forward.
# Handles errors and crafts reply messages reporting them, as appropriate.
# Defers to Sms::Decoder for intricacies of decoding.
class Sms::Processor

  attr_accessor :incoming_msg, :elmo_response, :reply, :forward

  def initialize(incoming_msg)
    @incoming_msg = incoming_msg
  end

  # Takes an incoming sms, decodes it, and constructs a reply and/or a forward.
  # Returns a hash with keys :reply and :forward. Either value may be nil.
  def process
    # abort if the SMS in question is from one of the incoming SMS numbers
    return if configatron.incoming_sms_numbers.include?(incoming_msg.from)

    reply_body = begin
      # decode and get the (ELMO) response
      self.elmo_response = Sms::Decoder.new(incoming_msg).decode

      # attempt to save it
      elmo_response.save!

      # send congrats!
      t_sms_msg("sms_form.decoding.congrats", user: elmo_response.user, form: elmo_response.form, mission: incoming_msg.mission)

    # if there is a decoding error, respond accordingly
    rescue Sms::DecodingError

      # If it's an automated sender, send no reply at all
      if $!.type == "automated_sender"
        nil
      else
        msg = t_sms_msg("sms_form.decoding.#{$!.type}", $!.params)

        # if this is an answer format error, add an intro to the beginning and add a period
        if $!.type =~ /^answer_not_/
          t_sms_msg("sms_form.decoding.answer_error_intro", $!.params) + " " + msg + "."
        else
          msg
        end
      end

    # if there is a validation error, respond accordingly
    rescue ActiveRecord::RecordInvalid
      # we only need to handle the first error
      field, error_msgs = elmo_response.errors.messages.first
      error_msg = error_msgs.first

      # get the orignal error key by inverting the dictionary
      # we use the system-wide locale since that's what the model would have used when generating the error
      dict = I18n.t("activerecord.errors.models.response")
      key = dict ? dict.invert[error_msg] : nil

      case key
      when :missing_answers
        # if it's the missing_answers error, we need to include which answers are missing
        # get the ranks
        ranks = elmo_response.missing_answers.map(&:rank).sort.join(",")

        # pluralize the translation key if appropriate
        key = "sms_form.validation.missing_answer"
        key += "s" if elmo_response.missing_answers.size > 1

        # translate
        t_sms_msg(key, ranks: ranks, user: elmo_response.user, form: elmo_response.form, mission: incoming_msg.mission)

      when :invalid_answers
        # if it's the invalid_answers error, we need to find the first answer that's invalid and report its error
        invalid_answer = elmo_response.answers.detect { |a| a.errors && a.errors.messages.size > 0 }
        t_sms_msg("sms_form.validation.invalid_answer",
          rank: invalid_answer.questioning.rank,
          error: invalid_answer.errors.messages.values.join(", "),
          user: elmo_response.user, form: elmo_response.form, mission: incoming_msg.mission)

      else
        # if we don't recognize the key, just use the regular message. it may not be pretty but it's better than nothing.
        error_msg
      end
    end

    if reply_body.present?
      self.reply = Sms::Reply.new(to: incoming_msg.from, body: reply_body, mission: incoming_msg.mission, user: incoming_msg.user)
    end

    {reply: reply, forward: handle_forward}
  end

  private

  # Decides if an SMS forward is called for, and builds and returns the Sms::Forward object if so.
  # Returns nil if no forward is called for, or if an error is encountered in constructing the message.
  def handle_forward
    form = elmo_response.try(:form)

    if form && form.sms_relay?
      broadcast = ::Broadcast.new(
        recipient_selection: "specific",
        recipient_users: form.recipient_users,
        recipient_groups: form.recipient_groups,
        source: "forward",
        medium: "sms_only",
        body: incoming_msg.body,
        which_phone: "both",
        mission: incoming_msg.mission
      )

      if broadcast.save
        message = strip_auth_code(incoming_msg.body, form)
        return Sms::Forward.new(broadcast: broadcast, body: message, mission: broadcast.mission)
      end
    end

    nil
  end

  # translates a message for the sms reply using the appropriate locale
  def t_sms_msg(key, options = {})
    # throw in the form_code if it's not there already and we have the form
    options[:form_code] ||= options[:form].current_version.code if options[:form]

    # get the reply language (if we have the user, use their pref_lang; if not, use default)
    lang = options[:user] && options[:user].pref_lang ? options[:user].pref_lang.to_sym : I18n.default_locale

    # do the translation, raising error on failure
    I18n.t(key, options.merge(locale: lang, raise: true))
  end

  def strip_auth_code(message, form)
    split_message = message.split(" ")
    split_message.shift if form.authenticate_sms?
    joined_message = split_message.join(" ")
  end
end
