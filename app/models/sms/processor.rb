# Takes an incoming Sms::Message and returns a translated and formatted reply and/or forward.
# Handles errors and crafts reply messages reporting them, as appropriate.
# Defers to Sms::Decoder for intricacies of decoding.
class Sms::Processor

  attr_accessor :incoming_msg, :reply, :forward, :all_incoming_numbers
  delegate :finalize, to: :decoder

  def initialize(incoming_msg)
    @incoming_msg = incoming_msg
    @all_incoming_numbers = Setting.pluck(:incoming_sms_numbers).compact.reduce(:concat)
  end

  # Takes an incoming sms, decodes it, and constructs a reply and/or a forward.
  # Returns a hash with keys :reply and :forward. Either value may be nil.
  def process
    # abort if the SMS in question is from one of the incoming SMS numbers
    return if all_incoming_numbers.include?(incoming_msg.from)

    self.reply = handle_reply
    self.forward = handle_forward
  end

  private

  def handle_reply
    if reply_body.present?
      self.reply = Sms::Reply.new(
        body: reply_body,
        reply_to: incoming_msg,
        to: incoming_msg.from,
        mission: incoming_msg.mission,
        user: incoming_msg.user
      )
    end
  end

  def reply_body
    @reply_body ||= begin
      # Decode and send congrats.
      decoder.decode
      t_sms_msg("sms_form.decoding.congrats")

    # if there is a decoding error, respond accordingly
    rescue Sms::DecodingError => err
      case err.type
      # If it's an automated sender, send no reply at all
      when "automated_sender"
        nil
      when "missing_answers"
        # if it's the missing_answers error, we need to include which answers are missing
        # get the ranks
        params = err.params
        missing_answers = params[:missing_answers]
        params[:ranks] = missing_answers.map(&:rank).sort.join(",")

        # pluralize the translation key if appropriate
        key = "sms_form.validation.missing_answer"
        key += "s" if missing_answers.size > 1

        # translate
        t_sms_msg(key, params)
      else
        msg = t_sms_msg("sms_form.decoding.#{err.type}", err.params)

        # if this is an answer format error, add an intro to the beginning and add a period
        if err.type =~ /^answer_not_/
          t_sms_msg("sms_form.decoding.answer_error_intro", err.params) + " " + msg + "."
        else
          msg
        end
      end
    end
  end

  # Decides if an SMS forward is called for, and builds and returns the Sms::Forward object if so.
  # Returns nil if no forward is called for, or if an error is encountered in constructing the message.
  def handle_forward
    return unless decoder.response_built?
    form = decoder.form

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

      if broadcast.valid?
        message = strip_auth_code(incoming_msg.body, form)
        return Sms::Forward.new(broadcast: broadcast, body: message, mission: broadcast.mission)
      end
    end

    nil
  end

  # translates a message for the sms reply using the appropriate locale
  def t_sms_msg(key, options = {})
    # Get some options from Response (if available) unless they're explicitly given
    if decoder.response_built?
      %i(user form mission).each { |a| options[a] = decoder.response.send(a) unless options.has_key?(a) }
    end

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

  def decoder
    @decoder ||= Sms::Decoder.new(incoming_msg)
  end
end
