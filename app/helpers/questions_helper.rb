module QuestionsHelper
  def questions_index_links(questions)
    links = []

    # links for form mode
    if params[:controller] == 'forms'
      # add the 'add questions to form' link if there are some questions
      unless @questions.empty?
        links << batch_op_link(:name => t("form.add_selected"), :path => add_questions_form_path(@form))
      end

      # add the create new questions link
      links << create_link(Question, :js => true) if can?(:create, Question)

    # otherwise, we're in regular questions mode
    else
      # add the create new question
      links << create_link(Question) if can?(:create, Question)

      add_import_standard_link_if_appropriate(links)
    end

    # return the link set
    links
  end

  def questions_index_fields
    fields = %w(std_icon code name type form_count answer_count)

    fields << 'published' unless admin_mode?

    # dont add the actions column if we're not in the forms controller, since that means we're probably in form#choose_questions
    fields << 'actions' unless params[:controller] == 'forms'

    fields
  end

  def format_questions_field(q, field)
    case field
    when "std_icon" then std_icon(q)
    when "type" then t(q.qtype_name, :scope => :question_type)
    when "published" then tbool(q.published?)
    when "answer_count" then number_with_delimiter(q.answer_count)
    when "actions" then table_action_links(q)
    when "name"
      if params[:controller] == 'forms'
        q.name + render_tags(q.sorted_tags)
      else
        link_to(q.name, q) + render_tags(q.sorted_tags, clickable: true)
      end
    else q.send(field)
    end
  end

  # Builds option tags for the given option sets. Adds multilevel data attrib.
  def option_set_select_option_tags(sets, selected_id)
    sets.map do |s|
      content_tag(:option, s.name, value: s.id, selected: s.id == selected_id ? 'selected' : nil, :'data-multilevel' => s.multi_level?)
    end.join.html_safe
  end
end
