module OptionsHelper
  def options_index_links(options)
    can?(:create, Option) ? [create_link(Option)] : []
  end
  
  def options_index_fields
    %w(name published actions)
  end
  
  def format_options_field(option, field)
    case field
    when "name" then link_to(option.name, option_path(option), :title => t("common.view"))
    when "published" then tbool(option.published?)
    when "actions" then action_links(option, :obj_name => option.name, :exclude => (option.published? ? [:destroy] : []))
    else option.send(field)
    end
  end
end
