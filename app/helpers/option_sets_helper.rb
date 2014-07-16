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
    when "options" then
      # only show the first 3 options as there could be many many
      option_set.options[0...3].collect{|o| o.name}.join(", ") + (option_set.options.size > 3 ? ', ...' : '')
    when "questions" then option_set.question_count
    when "answers" then number_with_delimiter(option_set.answer_count)
    when "actions" then
      # get standard action links
      links = table_action_links(option_set, :obj_name => option_set.name)

      # add a clone link if auth'd
      if can?(:clone, option_set)
        links += action_link("clone", clone_option_set_path(option_set), :'data-method' => 'put',
          :title => t("common.clone"), :confirm => t("option_set.clone_confirm", :name => option_set.name))
      end
    else option_set.send(field)
    end
  end
end
