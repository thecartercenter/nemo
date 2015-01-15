# Takes an incoming Sms::Message and returns a translated and formatted reply.
# Handles errors.
# Defers to Sms::Decoder for intricacies of decoding.
class Sms::Handler

  # takes an incoming sms and returns an outgoing one
  # may return nil if no response is appropriate
  def handle(sms)
    elmo_response = nil

    reply_body = begin
      # decode and get the (ELMO) response
      elmo_response = Sms::Decoder.new(sms).decode

      # attempt to save it
      elmo_response.save!

      # send congrats!
      t_sms_msg("sms_form.decoding.congrats", :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

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
        t_sms_msg(key, :ranks => ranks, :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

      when :invalid_answers
        # if it's the invalid_answers error, we need to find the first answer that's invalid and report its error
        invalid_answer = elmo_response.answers.detect{|a| a.errors && a.errors.messages.size > 0}
        t_sms_msg("sms_form.validation.invalid_answer", :rank => invalid_answer.questioning.rank,
          :error => invalid_answer.errors.messages.values.join(", "),
          :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

      else
        # if we don't recognize the key, just use the regular message. it may not be pretty but it's better than nothing.
        error_msg
      end
    end

    if reply_body.nil?
      return nil
    else
      return Sms::Reply.new(to: sms.from, body: reply_body, mission: sms.mission, user: sms.user)
    end
  end

  private
    # translates a message for the sms reply using the appropriate locale
    def t_sms_msg(key, options = {})
      # throw in the form_code if it's not there already and we have the form
      options[:form_code] ||= options[:form].current_version.code if options[:form]

      # get the reply language (if we have the user, use their pref_lang; if not, use default)
      lang = options[:user] && options[:user].pref_lang ? options[:user].pref_lang.to_sym : I18n.default_locale

      # do the translation, raising error on failure
      I18n.t(key, options.merge(:locale => lang, :raise => true))
    end
end
