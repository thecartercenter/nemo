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
      can?(:create, Broadcast) ? batch_op_link(:name => "Send Broadcast", :path => new_with_users_broadcasts_path) : nil,
      can?(:export, User) ? batch_op_link(:name => "Export as vCard", :path => export_users_path(:format => :vcf)) : nil,
      can?(:create, User) ? link_to("Create New User", new_user_path) : nil,
      can?(:create, User) ? link_to("Create Multiple Users", new_user_batch_path) : nil
    ]
  end
end
