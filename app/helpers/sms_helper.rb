module SmsHelper
  MAX_RECIPS_TO_SHOW = 3

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
      recips = sms.recipient_hashes(max: MAX_RECIPS_TO_SHOW).map { |r| user_with_phone(r[:user], r[:phone]) }.join('<br/>')
      recips + (sms.recipient_count > MAX_RECIPS_TO_SHOW ? "<br/>... and #{sms.recipient_count - MAX_RECIPS_TO_SHOW} more" : '')
    when "from" then
      user_with_phone sms.sender, sms.from
    else sms.send(field)
    end
  end

  def sms_messages_index_links(smses)
    []
  end

  def user_with_phone(user, phone = nil)
    if user == User::ELMO
      user.name + (phone.present? ? " <#{phone}>" : "")
    elsif user
      "#{link_to user.name, user_path(user)} <#{phone}>"
    else
      phone
    end
  end

end
