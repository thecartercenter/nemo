module QuestionsHelper
  def format_questions_field(q, field)
    case field
    when "name" then q.name_eng
    when "type" then q.type.long_name
    when "forms" then q.forms.size
    when "answers" then q.answers.size
    when "published?" then q.published? ? "Yes" : "No"
    when "actions"
      exclude = q.published? ? [:edit, :destroy] : []
      action_links(q, :destroy_warning => "Are you sure you want to delete question '#{q.code}'", :exclude => exclude)
    else q.send(field)
    end
  end
end
