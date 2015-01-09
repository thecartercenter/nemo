module SmsHelper
  def sms_messages_index_fields
    %w[type time to from body adapter_name]
  end

  def format_sms_messages_field(sms, field)
    case field
    when "type" then sms.type.split('::')[1]
    when "time" then
      if sms.sent_at <= sms.created_at - 1.minute
        time_diff = distance_of_time_in_words(sms.sent_at, sms.created_at, true, last_word_connector: ', ')
        "#{l(sms.created_at)} <br> (sent #{time_diff} earlier)"
      else
        l(sms.created_at)
      end
    when "to" then
      sms.recipient_hashes.map { |r|
        if r[:user] == "ELMO"
          "ELMO" + (r[:phone] ? " <#{r[:phone]}>" : "")
        elsif r[:user]
          "#{link_to r[:user].name, user_path(r[:user])} <#{r[:phone]}>"
        else
          r[:phone]
        end
      }.join(", ")
    else sms.send(field)
    end
  end

  def sms_messages_index_links(smses)
    []
  end

end
