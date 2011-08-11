module FormsHelper
  def format_forms_field(form, field)
    case field
    when "type" then form.type.name
    when "questions" then form.questions.size
    when "last_modified" then form.updated_at.strftime("%Y-%m-%d %l:%M%p")
    when "responses" 
      link_to(form.responses.size, start_searches_path(:query => "formname:\"#{form.name}\"", :class_name => "Response"))
    when "downloads" then form.downloads || 0
    when "published?" then form.is_published? ? "Yes" : "No"
    when "actions"
      exclude = form.is_published? ? [:edit, :destroy] : []
      action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
    else form.send(field)
    end
  end
end
