module ResponsesHelper
  def responses_index_fields
    %w(id form_id user_id created_at age reviewed duplicate actions)
  end
  
  def format_responses_field(resp, field)
    case field
    when "id" then link_to(resp.id, response_path(resp), :title => t("common.view"))
    when "form_id" then resp.form_name
    when "created_at" then resp.created_at ? l(resp.created_at) : ""
    when "age" then resp.created_at ? time_ago_in_words(resp.created_at) : ""
    when "reviewed" then tbool(resp.reviewed?)
    when "duplicate" then resp.duplicate? ? duplicate_notice(resp.duplicate) : ""
    when "user_id" then resp.submitter
    when "actions"
      # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
      # the controller actions will still be auth'd
      by = resp.user ? " by #{resp.user.name}" : ""
      action_links(resp, :obj_description => resp.user ? 
        "#{Response.model_name.human} #{t('common.by').downcase} #{resp.user.name}" : 
        "#{t('common.this').downcase} #{Response.model_name.human}")
    else resp.send(field)
    end
  end
  
  def duplicate_notice(resp)
    action_link("duplicate",{:action => "change_duplicate", :id => resp.id}, :method=> :put, :data => "#{resp.id}", :title => "Possible duplicate of Response ##{resp.id}")    
  end
  
  def responses_index_links(responses)
    links = []
    
    # only add the create response link if there are any published forms and the user is auth'd to create
    if !@pubd_forms.empty? && can?(:create, Response)
      links << create_link(Response, :js => true) + new_response_mini_form(false)
    end
    
    # only add the export link if there are responses and the user is auth'd to export
    if !responses.empty? && can?(:export, Response)
      links << link_to(t("response.export_to_csv"), responses_path(:format => :csv, :search => params[:search]))
    end
    
    # return the assembled list of links
    links
  end
  
  # builds a small inline form consisting of a dropdown for choosing a Form to which to submit a new response
  def new_response_mini_form(visible = true)
    form_tag(new_response_path, :method => :get, :id => "form_chooser", :style => visible ? "" : "display: none") do
      select_tag(:form_id, sel_opts_from_objs(@pubd_forms, :name_method => :full_name, :tags => true), 
        :prompt => t("form.choose_form"), :onchange => "this.form.submit()")
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
  
  # takes a recent count (e.g. [5, "week"]) and translates it
  def translate_recent_responses(count)
    if count.nil?
      t("welcome.no_recent")
    else
      tmd("welcome.in_the_past_#{count[1]}", :count => count[0])
    end
  end
end