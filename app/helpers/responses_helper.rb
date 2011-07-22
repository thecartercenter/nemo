module ResponsesHelper
  def format_responses_field(resp, field)
    case field
    when "observation_time" then resp.observed_at && resp.observed_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "submission_time" then resp.created_at && resp.created_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "age" then resp.created_at && time_ago_in_words(resp.created_at).gsub("about ", "") || ""
    when "reviewed?" then resp.reviewed? ? "Yes" : "No"
    when "place" then resp.place ? resp.place.full_name : ""
    when "actions"
      # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
      # the controller actions will still be auth'd
      by = resp.user ? " by #{resp.user.full_name}" : ""
      from = resp.place ? " from #{resp.place.long_name}" : ""
      action_links(resp, :destroy_warning => "Are you sure you want to delete the response#{by}#{from}? You won't be able to undelete it!")
    else resp.send(field)
    end
  end
  # calls the answer fields template for the given response
  def answers_subform(answers)
    content_tag("div", :class => "form") do 
      render(:partial => "answer", :collection => answers)
    end
  end
end
