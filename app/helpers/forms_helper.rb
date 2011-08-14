module FormsHelper
  def format_forms_field(form, field)
    case field
    when "type" then form.type.name
    when "questions" then form.questions.size
    when "last_modified" then form.updated_at.strftime("%Y-%m-%d %l:%M%p")
    when "responses"
      form.responses.size == 0 ? 0 :
        link_to(form.responses.size, start_searches_path(:query => "formname:\"#{form.name}\"", :class_name => "Response"))
    when "downloads" then form.downloads || 0
    when "published?" then form.is_published? ? "Yes" : "No"
    when "actions"
      exclude = form.is_published? ? [:edit, :destroy] : []
      al = action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
        
      # build confirm message for publish/unpublish link
      if form.is_published? && (form.downloads || 0) > 0
        pl_confirm = "Are you sure you want to unpublish form '#{form.name}'? It has already been downloaded " +
          "and any changes made to the form may cause problems during data submission."
      elsif !form.is_published?
        pl_confirm = "Are you sure you want to publish form '#{form.name}'? It will immediately be downloadable " + 
          "by all users."
      else
        pl_confirm = nil
      end
      pl_img = image_tag(form.is_published? ? "unpublish.png" : "publish.png")
      pl = link_to_if_auth(pl_img, publish_form_path(form), "forms#publish", form, 
        :title => "#{form.is_published? ? 'Unp' : 'P'}ublish", :confirm => pl_confirm)
      
      cl = link_to_if_auth(image_tag("clone.png"), clone_form_path(form), "forms#clone", form, 
        :title => "Clone", :confirm => "Are you sure you want to clone the form '#{form.name}'?")
      
      (al + pl + cl).html_safe
    else form.send(field)
    end
  end
end
