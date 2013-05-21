module QuestionsHelper
  def format_questions_field(q, field)
    case field
    when "title" then q.name_en
    when "type" then q.type.long_name
    when "published?" then q.published? ? "Yes" : "No"
    when "actions"
      exclude = q.published? ? [:edit, :destroy] : []
      action_links(q, :destroy_warning => "Are you sure you want to delete question '#{q.code}'", :exclude => exclude)
    else q.send(field)
    end
  end
  
  def questions_index_fields
    %w[code title type]
  end
  
  def questions_index_links(questions)
    links = []
    
    # add the 'add questions to form' link if there are some questions
    unless @questions.empty?
      links << batch_op_link(:name => "Add Selected Questions to Form", :path => add_questions_form_path(@form))
    end
    
    # add the create new questions link
    links << link_to("Create a New Question", "#", :class => "create_question") if can?(:create, Question)
    
    # return the link set
    links
  end
end
