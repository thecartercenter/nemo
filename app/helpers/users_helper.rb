module UsersHelper
  def format_users_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "language" then user.language.name
    when "actions"
      action_links(user, :exclude => :show,
        :destroy_warning => "Are you sure you want to delete #{user.first_name} #{user.last_name}?")
    else user.send(field)
    end
  end
end
