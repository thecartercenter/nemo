module LanguagesHelper
  def languages_index_fields
    %w[name code active? actions]
  end
  def languages_index_links(languages)
    [link_to_if_auth("Add new language", new_language_path, "languages#create")]
  end
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
