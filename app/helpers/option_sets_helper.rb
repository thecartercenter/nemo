module OptionSetsHelper
  def option_sets_index_links(option_sets)
    links = []
    links << create_link(OptionSet) if can?(:create, OptionSet)
    add_import_standard_link_if_appropriate(links)
    links
  end

  def option_sets_index_fields
    %w(std_icon name options questions answers published actions)
  end

  def format_option_sets_field(option_set, field)
    case field
    when "std_icon" then std_icon(option_set)
    when "name" then link_to(option_set.name, option_set_path(option_set), :title => t("common.view"))
    when "published" then tbool(option_set.published?)
    when "options" then option_set.options.collect{|o| o.name}.join(", ")
    when "questions" then option_set.question_count
    when "answers" then number_with_delimiter(option_set.answer_count)
    when "actions" then action_links(option_set, :obj_name => option_set.name)
    else option_set.send(field)
    end
  end
end
