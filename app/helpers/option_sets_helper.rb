module OptionSetsHelper
  def option_sets_index_links(option_sets)
    links = []
    links << create_link(OptionSet) if can?(:create, OptionSet)
    add_import_standard_link_if_appropriate(links)
    links
  end

  def option_sets_index_fields
    %w(std_icon name options questions answers) + (admin_mode? ? [] : ['published']) + ['actions']
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
      links = table_action_links(option_set)

      # add a clone link if auth'd
      if can?(:clone, option_set)
        links += action_link("clone", clone_option_set_path(option_set), :'data-method' => 'put',
          :title => t("common.clone"), :confirm => t("option_set.clone_confirm", :name => option_set.name))
      end
    else option_set.send(field)
    end
  end

  def cascading_select_input_id(input_name_template, id)
    input_name_template.gsub('###', id.to_s).gsub(/[\[\]]+/, '_').gsub(/_$/, '')
  end

  def multi_level_forbidden_notice
    text = tmd('option_set.multi_level_forbidden_notice')
    icon = content_tag(:i, '', class: 'fa fa-exclamation-triangle')
    content_tag(:div, (icon + content_tag(:div, text)).html_safe, class: "form-warning alert alert-info")
  end

  def huge_notice
    text = tmd('option_set.huge_notice', count: number_with_delimiter(@option_set.total_options))
    icon = content_tag(:i, '', class: 'fa fa-exclamation-triangle')
    content_tag(:div, (icon + content_tag(:div, text)).html_safe, class: "form-warning alert alert-info")
  end
end
