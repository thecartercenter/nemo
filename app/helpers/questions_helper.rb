module QuestionsHelper
  def questions_index_links(questions)
    links = []
    
    # add the 'add questions to form' link if there are some questions
    unless @questions.empty?
      links << batch_op_link(:name => t("form.add_selected"), :path => add_questions_form_path(@form))
    end
    
    # add the create new questions link
    links << create_link(Question, :js => true) if can?(:create, Question)
    
    # return the link set
    links
  end

  def questions_index_fields
    %w(code name type)
  end

  def format_questions_field(q, field)
    case field
    when "type" then t(q.qtype_name, :scope => :question_type)
    when "published?" then tbool(q.published?)
    when "actions" then action_links(q, :obj_name => q.code, :exclude => (q.published? ? [:edit, :destroy] : []))
    else q.send(field)
    end
  end
end
