module SearchesHelper
  def search_examples
    examples = I18n.t("search.examples.#{controller_name}", default: "")
    examples = safe_join(examples, "&nbsp;&nbsp;&nbsp;".html_safe) if examples.is_a?(Array)

    unless examples.blank?
      content_tag(:div, id: "search_examples") do
        t("common.example", count: examples.size).html_safe << "&nbsp;&nbsp;&nbsp;".html_safe << examples
      end
    end
  end

  def search_help_text_params
    if controller_name == 'questions'
      {question_types: QuestionType.all.map(&:human_name).join(', ')}
    else
      {}
    end
  end

  def all_forms
    Form.all.map { |form| {name: form.name, id: form.id} }
  end

  def all_users
    User.all.map { |user| {name: user.name, id: user.id} }
  end

  def all_groups
    UserGroup.all.map { |group| {name: group.name, id: group.id} }
  end
end
