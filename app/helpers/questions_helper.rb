# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module QuestionsHelper
  def questions_index_links(_questions)
    links = []
    # Links for when adding questions to form
    if params[:controller] == "forms"
      unless @questions.empty?
        links << batch_op_link(name: t("action_links.models.question.add_to_form"),
                               path: add_questions_form_path(@form))
      end
      links << link_divider
      links << create_link(Question, js: true) if can?(:create, Question)
    # Otherwise, we're in regular questions mode
    else
      links << batch_op_link(name: t("action_links.destroy"), path: bulk_destroy_questions_path,
                             confirm: "question.bulk_destroy_confirm")

      if can?(:export, Question)
        links << batch_op_link(name: t("action_links.export_csv"), path: export_questions_path)
      end

      links << link_divider
      links << create_link(Question) if can?(:create, Question)
      links << create_link(Questions::Import) if can?(:create, Questions::Import)
      add_import_standard_link_if_appropriate(links)
    end
    links
  end

  def questions_index_fields
    ["std_icon", "code", {attrib: "name", css_class: "has-tags"}, "type"]
  end

  def format_questions_field(question, field)
    case field.is_a?(Hash) ? field[:attrib] : field
    when "std_icon" then std_icon(question)
    when "type" then t(question.qtype_name, scope: :question_type)
    when "name"
      question_picker = params[:controller] == "forms"
      text = content_tag(:span, class: "text") do
        if question_picker
          html_escape(question.name_or_none)
        else
          link_to(question.name_or_none, question.default_path)
        end
      end
      text << render_tags(question.sorted_tags, clickable: !question_picker)
    else question.send(field)
    end
  end

  # Builds option tags for the given option sets. Adds multilevel data attrib.
  # If no option sets found, returns empty string.
  def option_set_select_option_tags(sets, selected_id)
    sets.map do |s|
      content_tag(:option, s.name, value: s.id, selected: s.id == selected_id ? "selected" : nil,
                                   "data-multilevel": s.multilevel?)
    end.reduce(:<<) || ""
  end

  def maxmin_strictly_label(method)
    t("question.maxmin.strictly_" + (method == :casted_minimum ? "gt" : "lt"))
  end
end
