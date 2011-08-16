module QuestioningsHelper
  def format_questionings_field(qing, field)
    case field
    when "rank"
      controller.action_name == "show" ? 
        qing.rank : 
        text_field_tag("rank[#{qing.id}]", qing.rank, :onchange => "form_recalc_ranks(this)")
    when "code", "name", "type" then format_questions_field(qing.question, field)
    when "required?", "hidden?" then qing.send(field) ? "Yes" : "No"
    when "actions"
      exclude = qing.published? || controller.action_name == "show" ? [:edit, :destroy] : []
      action_links(qing, :destroy_warning => "Are you sure you want to remove question '#{qing.code}' from this form", :exclude => exclude)
    else qing.send(field)
    end
  end
end
