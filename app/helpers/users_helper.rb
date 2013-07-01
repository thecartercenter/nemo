module UsersHelper
  def users_index_links(users)
    links = []
    links << batch_op_link(:name => t("broadcasts.send_broadcast"), :path => new_with_users_broadcasts_path) if can?(:create, Broadcast)
    links << batch_op_link(:name => t("users.export_vcard"), :path => export_users_path(:format => :vcf)) if can?(:export, User)
    links << create_link(User) if can?(:create, User)
    links << link_to(t("users.create_multiple"), new_user_batch_path) if can?(:create, User)
    links
  end

  def users_index_fields
    %w(name login email phone phone2 latest_mission actions)
  end

  def format_users_field(user, field)
    case field
    when "name" then link_to(user.name, user_path(user))
    when "email" then mail_to(user.email)
    when "latest_mission" then (lm = user.latest_mission) ? lm.name : "[#{t('common.none')}]"
    when "actions" then action_links(user, :obj_name => user.name)
    else user.send(field)
    end
  end
end
