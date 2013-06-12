module BroadcastsHelper
  def broadcasts_index_links(broadcasts)
    can?(:create, Broadcast) ? [link_to("Send Broadcast", new_broadcast_path)] : []
  end
  
  def broadcasts_index_fields
    %w(to medium created_at errors body)
  end
    
  def format_broadcasts_field(broadcast, field)
    case field
    when "to" then "#{broadcast.recipients.count} users"
    when "medium" then t("broadcasts.mediums.names." + broadcast.medium)
    when "body" then link_to(truncate(broadcast.body, :length => 100), broadcast_path(broadcast), :title => t("common.view"))
    when "created_at" then broadcast.created_at.to_s(:std_datetime)
    when "errors" then tbool(!broadcast.send_errors.blank?)
    else broadcast.send(field)
    end
  end
end
