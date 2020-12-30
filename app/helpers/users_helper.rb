# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module UsersHelper
  def users_index_links(_users)
    links = []
    if can?(:create, Broadcast) && !offline_mode?
      links << batch_op_link(name: t("action_links.models.user.send_broadcast"),
                             path: new_with_users_broadcasts_path(search: @search_params))
    end
    if can?(:export, User)
      links << batch_op_link(name: t("action_links.models.user.export_to_vcard"),
                             path: export_users_path(format: :vcf))
    end
    if can?(:bulk_destroy, User)
      links << batch_op_link(name: t("action_links.destroy"), path: bulk_destroy_users_path,
                             confirm: "user.bulk_destroy_confirm")
    end
    if can?(:view, UserGroup)
      links << link_to(t("action_links.models.user.add_to_group"), "#user-group-modal",
        class: "add-to-group batch-link")
      links << link_to(t("action_links.models.user.remove_from_group"), "#user-group-modal",
        class: "remove-from-group batch-link")
    end
    links << link_divider
    links << create_link(User) if can?(:create, User)
    links << link_to(t("action_links.import_from_csv"), new_user_import_path) if can?(:create, UserImport)
    links
  end

  def users_index_fields
    ["name", {attrib: "login", css_class: "has-tags"}, "email", "phone", "phone2", "admin"] <<
      (admin_mode? ? "latest_mission" : "role")
  end

  def format_users_field(user, field)
    case field.is_a?(Hash) ? field[:attrib] : field
    when "name"
      link_to(user.name + (user.active? ? "" : " (#{t('common.inactive')})"), user.default_path)
    when "login"
      content_tag(:span, sanitize(user.login), class: "text") <<
        render_tags(user.user_groups.all, clickable: true, link_method: :group_filter_link)
    when "email" then mail_to(user.email)
    when "latest_mission" then (lm = user.latest_mission) ? lm.name : "[#{t('common.none')}]"
    when "role" then t(user.roles[current_mission], scope: :role)
    when "admin" then user.admin? ? t("common._yes") : ""
    else user.send(field)
    end
  end

  def users_index_row_class(obj)
    obj.active? ? nil : "inactive"
  end

  def assignment_errors
    errors = []
    unless (msg = @user.errors[:'assignments.role']&.first).nil?
      errors << "#{User.human_attribute_name(:role)} #{msg}"
    end
    unless (msg = @user.errors[:'assignments.mission']&.first).nil?
      errors << "#{User.human_attribute_name(:mission_id)} #{msg}"
    end
    errors
  end

  def birth_year_options
    first_year = 120.years.ago.year
    last_year = Time.zone.now.year
    (first_year..last_year).to_a.reverse
  end
end
