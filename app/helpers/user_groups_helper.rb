module UserGroupsHelper
  def user_groups_index_fields
    %w(name users created_at filter actions)
  end

  def format_user_groups_field(group, field_name)
    case field_name
    when "name"
      group.name
    when "users"
      group.users.count
    when "created_at"
      l(group.created_at)
    when "filter"
      filter_link(group)
    when "actions" then table_action_links(group)
    end
  end

  def filter_link(group)
    qualifier = t('search_qualifiers.group')
    link_text = t('activerecord.action_links.user_group.members')
    query = %[#{qualifier}:"#{group.name}"]

    link_to link_text, users_path(search: query)
  end
end
