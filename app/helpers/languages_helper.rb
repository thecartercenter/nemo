module LanguagesHelper
  def format_language_field(language, field)
    case field
    when "actions"
      link_to("Edit", edit_language_path(language)) + " | " + 
        link_to("Delete", language, :method => :delete, :confirm => "Are you sure you want to delete #{language.name}?")
    else language.send(field)
    end
  end
end
