module OptionSetsHelper
  def option_sets_index_links(option_sets)
    [can?(:create, OptionSet) ? link_to("Add new option set", new_option_set_path) : nil]
  end
  
  def option_sets_index_fields
    %w[name options questions published? actions]
  end
  
  def format_option_sets_field(option_set, field)
    case field
    when "published?" then option_set.published? ? "Yes" : "No"
    when "options" then option_set.sorted_options.collect{|o| o.name_en}.join(", ")
    when "questions" then option_set.questions.size
    when "actions"
      exclude = option_set.published? ? [:edit, :destroy] : []
      action_links(option_set, :destroy_warning => "Are you sure you want to delete option set '#{option_set.name}'?", :exclude => exclude)
    else option_set.send(field)
    end
  end
end
