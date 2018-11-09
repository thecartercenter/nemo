module UsersHelper
  def users_index_links(users)
    links = []

    if can?(:create, Broadcast) && !offline_mode?
      links << batch_op_link(name: t("broadcast.send_broadcast"),
        path: new_with_users_broadcasts_path(search: @search_params))
    end

    if can?(:export, User)
      links << batch_op_link(name: t("user.export_vcard"), path: export_users_path(format: :vcf))
    end

    if can?(:bulk_destroy, User)
      links << batch_op_link(name: t("user.bulk_destroy"), path: bulk_destroy_users_path,
        confirm: "user.bulk_destroy_confirm")
    end

    links << create_link(User) if can?(:create, User)

    # Can't batch create users in admin mode since there is no mission to assign them to.
    links << link_to(t("user.create_multiple"), new_user_batch_path) if can?(:create, UserBatch)

    # links << link_to(t("user.list_groups"), "#user-group-modal", class: "list-groups") if can?(:view, UserGroup)
    links << link_to(t("user.add_to_group"), "#user-group-modal", class: "add-to-group") if can?(:view, UserGroup)
    links << link_to(t("user.remove_from_group"), "#user-group-modal", class: "remove-from-group") if can?(:view, UserGroup)

    links
  end

  def users_index_fields
    f = %w(name login email phone phone2 admin)
    f << (admin_mode? ? "latest_mission" : "role")
    f << "actions"
    f
  end

  def format_users_field(user, field)
    case field
    when "name"
      link_to(user.name + (user.active? ? "" : " (#{t('common.inactive')})"), user_path(user))
    when "login"
      sanitize(user.login) << render_groups(user.user_groups.all)
    when "email" then mail_to(user.email)
    when "latest_mission" then (lm = user.latest_mission) ? lm.name : "[#{t('common.none')}]"
    when "role" then t(user.roles[current_mission], scope: :role)
    when "admin" then user.admin? ? t("common._yes") : ""
    when "actions" then table_action_links(user)
    else user.send(field)
    end
  end

  def users_index_row_class(obj)
    obj.active? ? nil : "inactive"
  end

  def assignment_errors
    e = []
    e << User.human_attribute_name(:role) + " " + @user.errors[:'assignments.role'].first unless @user.errors[:'assignments.role'].empty?
    e << User.human_attribute_name(:mission_id) + " " + @user.errors[:'assignments.mission'].first unless @user.errors[:'assignments.mission'].empty?
    e
  end

  def birth_year_options
    first_year = 120.years.ago.year
    last_year = Time.zone.now.year
    (first_year..last_year).to_a.reverse
  end

  def country_options
    country_translations = {}
    I18n.t("countries").keys.each do |country_code|
      country_translations[code] = I18n.t(code, scope: :countries)
    end
    country_translations
  end
end
