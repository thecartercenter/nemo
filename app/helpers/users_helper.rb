module UsersHelper
  def format_user_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "language" then user.language.name
    when "actions"
      link_to("Edit", edit_user_path(user)) + " | " +
        link_to("Delete", user, :method => :delete, :confirm => "Are you sure you want to delete #{user.first_name} #{user.last_name}?")
    else user.send(field)
    end
  end
end
