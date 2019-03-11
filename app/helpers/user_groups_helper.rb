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

  def filter_link(group)
    qualifier = I18n.t("search_qualifiers.group")
    link_text = group.name.to_s
    query = %(#{qualifier}:"#{group.name}")
    link_to(link_text, users_path(search: query))
  end

  def render_groups(groups, options = {})
    if groups.present?
      content_tag(:ul, class: "tags groups #{options[:class]}") do
        groups.map do |group|
          render_group(group, profile_mode: options[:profile_mode])
        end.reduce(:<<)
      end
    else
      ""
    end
  end

  def render_group(group, options = {})
    content_tag(:li, group.name, class: "token-input-token-elmo group") do
      options[:profile_mode] ? group.name : filter_link(group)
    end
  end
end
