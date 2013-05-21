module QuestioningsHelper
  def format_questionings_field(qing, field)
    case field
    when "rank" then controller.action_name == "show" ? qing.rank : text_field_tag("rank[#{qing.id}]", qing.rank, :class => "rank_box")
    when "code", "title", "type" then format_questions_field(qing.question, field)
    when "condition?" then qing.has_condition? ? "Yes" : "No"
    when "required?", "hidden?" then qing.send(field) ? "Yes" : "No"
    when "actions"
      exclude = [:destroy]
      exclude << :edit if qing.published? || controller.action_name == "show"
      action_links(qing, :destroy_warning => "Are you sure you want to remove question '#{qing.code}' from this form", :exclude => exclude)
    else qing.send(field)
    end
  end
  
  def questionings_index_links(qings)
    links = []
    
    # these links only make sense if we're editing
    if controller.action_name == "edit"
      # add questions link
      links << link_to("Add Questions", choose_questions_form_path(@form))
      
      # these links only make sense if there are questions
      if qings.size > 0
        # add remove questions link
        links << batch_op_link(:name => "Remove Selected", :path => remove_questions_form_path(@form),
          :confirm => "Are you sure you want to remove these ### question(s) from the form?")
        
        # add publish link
        links << link_to("Publish Form", publish_form_path(@form))
      end
    end
    
    # can print from show action, if there are questions
    if qings.size > 0
      links << link_to("Print Form", "#", :onclick => "Form.print(#{qings.first.form.id}); return false;") + " " +
        loading_indicator(:id => qings.first.form.id)
    end
    
    # add the sms guide link if appropriate
    if qings.size > 0 && qings.first.form.smsable? && qings.first.form.published?
      links << link_to("View SMS Guide", form_path(qings.first.form, :sms_guide => 1))
    end
    
    # return the array of links we built
    links
  end
  
  def questionings_index_fields
    %w[rank code title type condition? required? hidden? actions]
  end
end
