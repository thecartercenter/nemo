module FormsHelper
  def forms_index_links(forms)
    [link_to_if_auth("Create Form", new_form_path, "forms#create")]
  end
  
  def forms_index_fields
    %w[type name questions published? last_modified downloads responses actions]
  end
    
  def format_forms_field(form, field)
    case field
    when "type" then form.type.name
    when "questions" then form.questions.size
    when "last_modified" then form.updated_at.strftime("%Y-%m-%d %l:%M%p")
    when "responses"
      form.responses.size == 0 ? 0 :
        link_to(form.responses.size, start_searches_path(:query => "formname:\"#{form.name}\"", :class_name => "Response"))
    when "downloads" then form.downloads || 0
    when "published?" then form.published? ? "Yes" : "No"
    when "actions"
      exclude = form.published? ? [:edit, :destroy] : []
      al = action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
        
      # build confirm message for publish/unpublish link
      if form.published?
        pl_confirm = "Are you sure you want to unpublish form '#{form.name}'? " + 
          "Any changes made to the form may cause problems during data submission."
      else
        pl_confirm = "Are you sure you want to publish form '#{form.name}'? It will immediately be downloadable " + 
          "by all users."
      end
      pl_img = image_tag(form.published? ? "unpublish.png" : "publish.png")
      pl = link_to_if_auth(pl_img, publish_form_path(form), "forms#publish", form, 
        :title => "#{form.published? ? 'Unp' : 'P'}ublish", :confirm => pl_confirm)
      
      cl = link_to_if_auth(image_tag("clone.png"), clone_form_path(form), "forms#clone", form, 
        :title => "Clone", :confirm => "Are you sure you want to clone the form '#{form.name}'?")
      
      (al + pl + cl).html_safe
    else form.send(field)
    end
  end
end
