module BroadcastsHelper
  def broadcasts_index_links(broadcasts)
    can?(:create, Broadcast) ? [link_to(t("broadcast.send_broadcast"), new_broadcast_path)] : []
  end

  def broadcasts_index_fields
    %w(recipients medium created_at errors body)
  end

  def format_broadcasts_field(broadcast, field)
    case field
    when "recipients"
      if broadcast.recipient_selection == "specific"
        t("broadcast.user_count", count: broadcast.recipients.count)
      else
        t("broadcast.recipient_selection_options.#{broadcast.recipient_selection}")
      end
    when "medium"
      t("broadcast.mediums.names." + broadcast.medium)
    when "body"
      link_to(truncate(broadcast.body, :length => 100), broadcast_path(broadcast), :title => t("common.view"))
    when "created_at"
      l(broadcast.created_at)
    when "errors"
      tbool(!broadcast.send_errors.blank?)
    else
      broadcast.send(field)
    end
  end
end
