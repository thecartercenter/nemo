module UserGroupsHelper
  def user_groups_index_fields
    if @add_mode
      %w(name users created_at)
    else
      %w(name users created_at filter actions)
    end
  end

  def format_user_groups_field(group, field_name)
    case field_name
    when "name"
      if @add_mode
        link_to group.name, user_group_add_users_path(group), class: "add-to-group"
      else
        group.name
      end
    when "users"
      group.users.count
    when "created_at"
      l(group.created_at)
    when "filter"
      filter_link(group)
    when "actions"
      table_action_links(group, ajax_mode: true)
    end
  end

  def filter_link(group)
    qualifier = I18n.t('search_qualifiers.group')
    link_text = I18n.t('activerecord.action_links.user_group.members')
    query = %[#{qualifier}:"#{group.name}"]

    link_to link_text, users_path(search: query)
  end
end
