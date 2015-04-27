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
        time_diff = time_diff(sms.sent_at, sms.created_at)
        t('sms.timestamp_with_diff', time: l(sms.created_at), time_diff: time_diff)
      else
        l(sms.created_at)
      end
    when "to" then
      recips = sms.recipient_hashes(max: MAX_RECIPS_TO_SHOW).map { |r| user_with_phone(r[:user], r[:phone]) }.join('<br/>')
      extra_recipients = sms.recipient_count - MAX_RECIPS_TO_SHOW
      recips << (extra_recipients > 0 ? t('sms.extra_recipients', count: extra_recipients) : '')
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
      user.name + (phone.present? ? " <small>(#{phone})</small>" : "")
    elsif user
      "#{link_to user.name, user_path(user)} <small>(#{phone})</small>"
    else
      phone
    end
  end

  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60

    str = ""
    str << "#{hours}h" if hours > 0
    str << "#{minutes}m"
    str
  end

end
