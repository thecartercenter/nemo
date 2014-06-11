module SmsHelper
  def sms_messages_index_fields
    %w[direction sent_at received_at body adapter_name]
  end

  def format_sms_messages_field(sms, field)
    case field
    when "to" then sms.to.is_a?(Array) ? sms.to.join(", ") : sms.to
    when "sent_at" then l(sms.sent_at)
    when "received_at" then l(sms.received_at) unless sms.received_at.blank?
    when "direction" then I18n.t("common.#{sms.send(field)}") unless sms.send(field).blank?
    else sms.send(field)
    end
  end

  def sms_messages_index_links(smses)
    []
  end
end
