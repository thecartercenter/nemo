module BrodcastsHelper
  def format_broadcasts_field(broadcast, field)
    case field
    when "to" then "#{broadcast.recipients.count} users"
    when "medium" then broadcast.medium.capitalize
    when "message" then truncate(broadcast.body, :length => 100)
    when "sent_at" then broadcast.created_at.strftime("%Y-%m-%d %l:%M%p")
    when "errors?" then broadcast.send_errors.blank? ? "No" : "Yes"
    when "actions" then action_links(broadcast, :exclude => [:edit, :destroy])
    else broadcast.send(field)
    end
  end
end
