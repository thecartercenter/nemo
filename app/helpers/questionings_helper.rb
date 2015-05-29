module QuestioningsHelper
  def questionings_index_links(qings)
    [].tap do |links|
      if controller.action_name == "edit"
        links << link_to(t("form.add_questions"), choose_questions_form_path(@form)) if can?(:add_questions, @form)

        if qings.any?
          # add remove questions link
          links << batch_op_link(:name => t("form.remove_selected"), :path => remove_questions_form_path(@form),
            :confirm => t("form.remove_question_confirm")) if can?(:remove_questions, @form)
        end
      end
    end
  end

  def questionings_index_fields
    %w(std_icon rank code name type condition required hidden actions)
  end

  def format_questionings_field(qing, field)
    case field
    when "std_icon" then std_icon(qing)
    when "name"
      link_to(qing.question.name, questioning_path(qing), :title => t("common.view")) +
        render_tags(qing.question.sorted_tags)
    when "rank"
      if controller.action_name == "show" || cannot?(:reorder_questions, qing.form)
        qing.rank
      else
        text_field_tag("rank[#{qing.id}]", qing.rank, :class => "rank_box")
      end
    when "code", "name", "type" then format_questions_field(qing.question, field)
    when "condition" then tbool(qing.has_condition?)
    when "required", "hidden" then tbool(qing.send(field))
    when "actions" then table_action_links(qing)
    else qing.send(field)
    end
  end
end
