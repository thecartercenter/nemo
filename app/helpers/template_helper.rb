module TemplateHelper

  # gets html for profile icon, username, and role in header
  def profile_link
    # if not in admin mode, show mission and role info
    if !admin_mode?
      # get current role
      if current_mission
        role = "(" + t(current_user.admin? ? :admin : current_user.role(current_mission), :scope => :role) + ")"
      end
    else
      role = tag("br")
    end

    return content_tag('i', '', {:class => 'fa fa-2x fa-user', :title => t("page_titles.users.edit_profile")}) + tag("br") +
      current_user.login + tag("br") + role
  end


  # gets html for admin mode icon
  def admin_link
    if admin_mode?
      link_to(content_tag('i', '', :class => 'fa fa-2x fa-times') + tag("br") + t('admin_mode.exit_admin_mode'),
        exit_admin_mode_user_url(current_user),
        :class => 'exit_admin_mode admin-mode', :title => t('admin_mode.exit_admin_mode'))
    else
      link_to(content_tag('i', '', :class => 'fa fa-2x fa-key admin') +
        content_tag('span', t('admin_mode.goto_admin_mode'), :class => 'admin'),
        admin_root_url(:mode => 'admin'), :class => 'goto_admin_mode admin-mode', :title => t('admin_mode.goto_admin_mode'))
    end
  end

end
