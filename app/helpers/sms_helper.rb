module SmsHelper
  def sms_messages_index_fields
    %w[type time to from body adapter_name]
  end

  def format_sms_messages_field(sms, field)
    case field
    when "type" then sms.type.split('::')[1]
    when "time" then
      if sms.sent_at < sms.created_at - 1.minute
        "#{l(sms.created_at)} (sent -#{Time.diff(sms.created_at, sms.sent_at, '%H %N %S')[:diff]})"
      else
        l(sms.created_at)
      end
    when "to" then
      begin
        sms.recipients.join(", ")
      rescue NotImplementedError
        sms.to
      end
    else sms.send(field)
    end
  end

  def sms_messages_index_links(smses)
    []
  end
end
