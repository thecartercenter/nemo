module QuestioningsHelper
  def questionings_index_links(qings)
    links = []

    # these links only make sense if we're editing
    if controller.action_name == "edit"
      # add questions link
      links << link_to(t("form.add_questions"), choose_questions_form_path(@form)) if can?(:add_questions, @form)

      # these links only make sense if there are questions
      if qings.size > 0
        # add remove questions link
        links << batch_op_link(:name => t("form.remove_selected"), :path => remove_questions_form_path(@form),
          :confirm => t("form.remove_question_confirm")) if can?(:remove_questions, @form)

        # add publish link if allowed
        if can?(:publish, @form)
          key = @form.published? ? 'unpublish_form' : 'publish_form'
          lbl = t("form.#{key}")
          links << link_to("#{lbl}", publish_form_path(@form))
        end
      end
    end

    # can print from show action, if there are questions
    if qings.size > 0
      links << link_to("#{t('form.print_form')}", "#", :onclick => "Form.print(#{qings.first.form.id}); return false;") + " " +
        loading_indicator(:id => qings.first.form.id)
    end

    # add the sms guide link if appropriate
    if qings.size > 0 && qings.first.form.smsable? && qings.first.form.published? && !admin_mode?
      links << link_to(t("form.view_sms_guide"), form_path(qings.first.form, :sms_guide => 1))
    end

    # add the sms test console link if appropriate
    if qings.size > 0 && qings.first.form.smsable? && !admin_mode? && can?(:create, Sms::Test)
      links << link_to(t("page_titles.sms_tests.all"), new_sms_test_path)
    end

    # return the array of links we built
    links
  end

  def questionings_index_fields
    %w(std_icon rank code name type condition required hidden actions)
  end

  def format_questionings_field(qing, field)
    case field
    when "std_icon" then std_icon(qing)
    when "name" then link_to(qing.question.name, questioning_path(qing), :title => t("common.view"))
    when "rank"
      if controller.action_name == "show" || cannot?(:reorder_questions, qing.form)
        qing.rank
      else
        text_field_tag("rank[#{qing.id}]", qing.rank, :class => "rank_box")
      end
    when "code", "name", "type" then format_questions_field(qing.question, field)
    when "condition" then tbool(qing.has_condition?)
    when "required", "hidden" then tbool(qing.send(field))
    when "actions" then action_links(qing, :obj_name => qing.code)
    else qing.send(field)
    end
  end
end
