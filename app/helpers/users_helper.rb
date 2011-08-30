module UsersHelper
  def users_index_fields
    %w[last_name first_name login email language role device phone_number active? actions]
  end
  def format_users_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "language" then user.language.name
    when "active?" then user.active? ? "Yes" : "No"
    when "actions"
      action_links(user, :exclude => :show,
        :destroy_warning => "Are you sure you want to delete #{user.first_name} #{user.last_name}?")
    else user.send(field)
    end
  end
  def users_index_links(users)
    [
      batch_op_link(:name => "Send Broadcast", :action => "broadcasts#new_with_users"),
      batch_op_link(:name => "Export as vCard", :action => "users#export", :format => :vcf),
      link_to_if_auth("Create new user", new_user_path, "users#create")
    ]
  end
end
