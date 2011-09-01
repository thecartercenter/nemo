module ResponsesHelper
  def responses_index_fields
    %w[form_name place submitter observation_time submission_time age reviewed? actions]
  end
  def format_responses_field(resp, field)
    case field
    when "observation_time" then resp.observed_at && resp.observed_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "submission_time" then resp.created_at && resp.created_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "age" then resp.created_at && time_ago_in_words(resp.created_at).gsub("about ", "") || ""
    when "reviewed?" then resp.reviewed? ? "Yes" : "No"
    when "place" then resp.place ? truncate(resp.place.full_name, :length => 40) : ""
    when "actions"
      # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
      # the controller actions will still be auth'd
      by = resp.user ? " by #{resp.user.full_name}" : ""
      from = resp.place ? " from #{resp.place.long_name}" : ""
      action_links(resp, :destroy_warning => "Are you sure you want to delete the response#{by}#{from}? You won't be able to undelete it!")
    else resp.send(field)
    end
  end
  def responses_index_links(responses)
    mini_form = form_tag(new_response_url, {:id => "form_chooser", :style => "display: none"}) do
      select_tag(:form_id, options_for_select(Form.select_options(:published => true)), 
        :include_blank => "Select a published form...") +
        submit_tag("Go")
    end
    
    [link_to_if_auth("Create new response", "#", "responses#create", nil, 
      :onclick => "$('form_chooser').show(); return false") + mini_form,
     link_to_if_auth("Export all to CSV", responses_path(:format => :csv), "responses#index", nil)]
  end
  # calls the answer fields template for the given response
  def answers_subform(answers)
    content_tag("table", :class => "form answers") do
      content_tag("tr"){content_tag("th", :colspan => 3){"Answers"}} +
        render(:partial => "answer", :collection => answers)
    end
  end
end
