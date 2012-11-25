module UsersHelper
  def users_index_fields
    %w[name login email main_phone alternate_phone latest_mission actions]
  end
  def format_users_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "main_phone" then user.phone
    when "alternate_phone" then user.phone2
    when "latest_mission" then (lm = user.latest_mission) ? lm.name : "[None]"
    when "actions"
      action_links(user, :exclude => :show,
        :destroy_warning => "Are you sure you want to delete #{user.name}?")
    else user.send(field)
    end
  end
  def users_index_links(users)
    [
      batch_op_link(:name => "Send Broadcast", :action => "broadcasts#new_with_users"),
      batch_op_link(:name => "Export as vCard", :action => "users#export", :format => :vcf),
      link_to_if_auth("Create New User", new_user_path, "users#create"),
      link_to_if_auth("Create Multiple Users", new_user_batch_path, "users#create")
    ]
  end
end
