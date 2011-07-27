module OptionsHelper
  def format_options_field(option, field)
    case field
    when "name" then option.name_eng
    when "published?" then option.published? ? "Yes" : "No"
    when "actions"
      exclude = option.published? ? [:edit, :destroy] : []
      action_links(option, :destroy_warning => "Are you sure you want to delete option '#{option.name_eng}'?", 
        :exclude => exclude)
    else option.send(field)
    end
  end
end
