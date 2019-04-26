# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module UserGroupsHelper
  def user_groups_index_fields
    if @add_mode || @remove_mode
      %w[name users created_at]
    else
      %w[name users created_at filter actions]
    end
  end

  def format_user_groups_field(group, field_name)
    case field_name
    when "name"
      if @add_mode
        link_to(group.name, user_group_add_users_path(group), class: "add-to-group")
      elsif @remove_mode
        link_to(group.name, user_group_remove_users_path(group), class: "remove-from-group")
      else
        group.name
      end
    when "users" then group.users.count
    when "created_at" then l(group.created_at)
    when "filter" then filter_link(group)
    end
  end

  def group_filter_link(group, html_options)
    qualifier = I18n.t("search_qualifiers.group")
    link_text = group.name.to_s
    query = %(#{qualifier}:"#{group.name}")
    link_to(link_text, users_path(search: query), html_options)
  end
end
