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
    end
    
    # return the link set
    links
  end

  def questions_index_fields
    # fields for form mode
    fields = %w(std_icon code name type forms)

    # dont add published if in admin mode
    fields << 'published' unless admin_mode?

    # dont add the actions column if we're not in the forms controller, since that means we're probably in form#choose_questions
    fields << 'actions' unless params[:controller] == 'forms'
  end

  def format_questions_field(q, field)
    case field
    when "std_icon" then std_icon(q)
    when "type" then t(q.qtype_name, :scope => :question_type)
    when "published" then tbool(q.published?)
    when "forms" then q.form_count
    when "actions"
      exclude = []
      exclude << :destroy if cannot?(:destroy, q)
      action_links(q, :obj_name => q.code, :exclude => exclude)
    when "name"
      params[:controller] == 'forms' ? q.name : link_to(q.name, q)
    else q.send(field)
    end
  end
end
