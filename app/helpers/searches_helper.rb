# frozen_string_literal: true

module SearchesHelper
  def search_examples
    examples = I18n.t("search.examples.#{controller_name}", default: "")
    examples = safe_join(examples, "&nbsp;&nbsp;&nbsp;".html_safe) if examples.is_a?(Array)

    if examples.present?
      content_tag(:div, id: "search_examples") do
        t("common.example", count: examples.size).html_safe << "&nbsp;&nbsp;&nbsp;".html_safe << examples
      end
    end
  end

  def search_help_text_params
    if controller_name == "questions"
      {question_types: QuestionType.all.map(&:human_name).join(", ")}
    else
      {}
    end
  end
end
