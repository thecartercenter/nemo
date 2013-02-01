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
    when "questions" then form.questionings_count
    when "last_modified" then form.updated_at.to_s(:std_datetime)
    when "responses"
      form.responses_count == 0 ? 0 :
        link_to(form.responses_count, responses_path(:search => "formname:\"#{form.name}\""))
    when "downloads" then form.downloads || 0
    when "published?" then form.published? ? "Yes" : "No"
    when "actions"
      exclude = form.published? ? [:edit, :destroy] : []
      action_links = action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
        
      pl_img = action_icon(form.published? ? "unpublish" : "publish")
      publish_link = link_to_if_auth(pl_img, publish_form_path(form), "forms#publish", form, 
        :title => "#{form.published? ? 'Unp' : 'P'}ublish")
      
      clone_link = link_to_if_auth(action_icon("clone"), clone_form_path(form), "forms#clone", form, 
        :title => "Clone", :confirm => "Are you sure you want to make a copy of the form '#{form.name}'?")

      print_link = link_to_if_auth(action_icon("print"), "#", "forms#show", form, :title => "Print",
        :onclick => "Form.print(#{form.id}); return false;")
      
      (action_links + publish_link + clone_link + print_link + loading_indicator(:id => form.id, :floating => true)).html_safe
    else form.send(field)
    end
  end
  
  # given a Questioning object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(qing, &block)
    opts = {}
    opts[:ref] = "/data/#{qing.question.odk_code}"
    opts[:appearance] = "tall" if qing.question.type.name == "long_text"
    content_tag(qing.question.type.odk_tag, opts, &block)
  end
end
