module OptionsHelper
  def options_index_links(options)
    [can?(:create, Option) ? link_to("Add new option", new_option_path) : nil]
  end
  
  def options_index_fields
    %w[name value published? actions]
  end
  
  def format_options_field(option, field)
    case field
    when "name" then option.name_en
    when "published?" then option.published? ? "Yes" : "No"
    when "actions"
      exclude = option.published? ? [:destroy] : []
      action_links(option, :destroy_warning => "Are you sure you want to delete option '#{option.name_en}'?", 
        :exclude => exclude)
    else option.send(field)
    end
  end
end
