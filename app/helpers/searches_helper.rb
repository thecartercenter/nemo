module SearchesHelper
  def search_examples
    examples = I18n.t("search.examples.#{controller_name}", :default => "")
    examples = examples.join("&nbsp;&nbsp;&nbsp;") if examples.is_a?(Array)

    unless examples.blank?
      content_tag("div", :id => "search_examples") do
        ("#{t("common.example", :count => 2)}:&nbsp;&nbsp;&nbsp;#{examples}").html_safe
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
end