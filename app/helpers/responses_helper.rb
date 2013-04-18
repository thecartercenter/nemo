module ResponsesHelper
  def responses_index_fields
    %w[form_name submitter submission_time age reviewed? duplicate actions]
  end
  
  def format_responses_field(resp, field)
    case field
    when "submission_time" then resp.created_at && resp.created_at.to_s(:std_datetime) || ""
    when "age" then resp.created_at && time_ago_in_words(resp.created_at).gsub("about ", "") || ""
    when "reviewed?" then resp.reviewed? ? "Yes" : "No"
    when "duplicate" then resp.duplicate? ? "Yes" : "No"
    when "actions"
      # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
      # the controller actions will still be auth'd
      by = resp.user ? " by #{resp.user.name}" : ""
      action_links(resp, :destroy_warning => "Are you sure you want to delete the response#{by}? You won't be able to undelete it!")
    else resp.send(field)
    end
  end
  
  def responses_index_links(responses)
    links = []
    # only add the create response link if there are any published forms
    unless @pubd_forms.empty?
      links << link_to_if_auth("Create new response", "#", "responses#create", nil, 
        :onclick => "$('#form_chooser').show(); return false") + new_response_mini_form(false)
    end
    unless responses.empty?
      links << link_to_if_auth("Export to CSV", responses_path(:format => :csv, :search => params[:search]), "responses#index", nil)
    end
    links
  end
  
  def new_response_mini_form(visible = true)
    form_tag(new_response_path, :method => :get, :id => "form_chooser", :style => visible ? "" : "display: none") do
      select_tag(:form_id, sel_opts_from_objs(@pubd_forms, :name_method => :full_name, :tags => true), 
        :prompt => "Choose a Form...", :onchange => "this.form.submit()")
    end
  end
  
  # converts the given responses to csv
  def responses_to_csv(responses)
    if responses.empty?
      ""
    else
      CSV.generate do |csv|
        # add header row
        csv << responses.first.attributes.keys
        
        # add rest of rows
        responses.each{|r| csv << r.attributes.values}
      end
    end
  end
end