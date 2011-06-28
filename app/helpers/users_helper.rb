module UsersHelper
  def format_users_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "language" then user.language.name
    when "actions"
      links = []
      links << link_to_if_auth("Edit", edit_user_path(user), "users#update", user)
      links << link_to_if_auth("Delete", user, "users#destroy", user,
        :method => :delete, :confirm => "Are you sure you want to delete #{user.first_name} #{user.last_name}?")
      links.reject{|l| l.blank?}.join(" | ").html_safe
    else user.send(field)
    end
  end
end
