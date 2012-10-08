module BroadcastsHelper
  def broadcasts_index_links(broadcasts)
    [link_to_if_auth("Send Broadcast", new_broadcast_path, "broadcasts#create")]
  end
  
  def broadcasts_index_fields
    %w[to medium sent_at errors? message actions]
  end
    
  def format_broadcasts_field(broadcast, field)
    case field
    when "to" then "#{broadcast.recipients.count} users"
    when "medium" then broadcast.medium.gsub("_", " ").ucwords
    when "message" then truncate(broadcast.body, :length => 100)
    when "sent_at" then broadcast.created_at.to_s(:std_datetime)
    when "errors?" then broadcast.send_errors.blank? ? "No" : "Yes"
    when "actions" then action_links(broadcast, :exclude => [:edit, :destroy])
    else broadcast.send(field)
    end
  end
end
