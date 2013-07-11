module SmsHelper
  def sms_messages_index_fields
    %w[to from body adapter_name sent_at]
  end

  def format_sms_messages_field(sms, field)
    case field
    when "body" then truncate(sms.body, :length => 180)
    when "to" then sms.to.is_a?(Array) ? sms.to.join(", ") : sms.to
    when "sent_at" then l(sms.sent_at)
    else sms.send(field)
    end
  end

  def sms_messages_index_links(smses)
    []
  end
end