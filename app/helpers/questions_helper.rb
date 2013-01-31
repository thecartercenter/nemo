module QuestionsHelper
  def format_questions_field(q, field)
    case field
    when "title" then q.name_eng
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
    unless @questions.empty?
      links << batch_op_link(:name => "Add Selected Questions to Form", :action => "forms#add_questions", :id => @form.id)
    end
    links << link_to_if_auth("Create a New Question", "#", "questionings#create", {}, :class => "create_question")
    links
  end
end
