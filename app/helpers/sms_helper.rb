module SmsHelper
  def sms_messages_index_fields
    %w[to from body sent_at]
  end

  def format_sms_messages_field(sms, field)
    field == "body" ? truncate(sms.body, :length => 180) : (field == "to" && sms.to.is_a?(Array) ? sms.to.join(", ") : sms.send(field))
  end

  def sms_messages_index_links(smses)
    []
  end
end