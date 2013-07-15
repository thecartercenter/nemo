module OptionSetsHelper
  def option_sets_index_links(option_sets)
    can?(:create, OptionSet) ? [create_link(OptionSet)] : []
  end
  
  def option_sets_index_fields
    %w(name options questions published actions)
  end
  
  def format_option_sets_field(option_set, field)
    case field
    when "name" then link_to(option_set.name, option_set_path(option_set), :title => t("common.view"))
    when "published" then tbool(option_set.published?)
    when "options" then option_set.options.collect{|o| o.name}.join(", ")
    when "questions" then option_set.questions.size
    when "actions" then action_links(option_set, :obj_name => option_set.name, :exclude => (option_set.published? ? [:destroy] : []))
    else option_set.send(field)
    end
  end
end
