# frozen_string_literal: true

module TemplateHelper
  # gets html for profile icon, username, and role in header
  def profile_link
    # show mission and role info only if not in admin mode
    if admin_mode?
      role_html = tag("br")
    elsif current_mission
      role = current_user.admin? ? :admin : current_user.role(current_mission)
      role_html = "(#{t(role, scope: :role)})"
    end

    content_tag(:i, "", class: "fa fa-2x fa-user", title: t("page_titles.users.edit_profile")) +
      tag("br") + current_user.login + tag("br") + role_html
  end

  def admin_mode_link
    verb = admin_mode? ? "exit" : "goto"
    icon = admin_mode? ? "times" : "key"
    text = t("admin_mode.#{verb}_admin_mode")
    path = admin_mode? ? admin_mode_exit_path : admin_root_path
    link_to(content_tag(:i, "", class: "fa fa-2x fa-#{icon}") + tag("br") + text, path,
      class: "admin-mode #{verb}-admin-mode", title: text)
  end
end
