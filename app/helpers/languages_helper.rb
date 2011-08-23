module LanguagesHelper
  def format_languages_field(language, field)
    case field
    when "active?" then language.active? ? "Yes" : "No"
    when "actions"
      action_links(language, :exclude => :show, 
        :destroy_warning => "Are you sure you want to delete #{language.name}?")
    else language.send(field)
    end
  end
end
