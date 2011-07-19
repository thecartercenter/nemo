module ResponsesHelper
  def format_responses_field(resp, field)
    case field
    when "observation_time" then resp.observed_at && resp.observed_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "submission_time" then resp.created_at && resp.created_at.strftime("%Y-%m-%d %l:%M%p") || ""
    when "age" then resp.created_at && time_ago_in_words(resp.created_at).gsub("about ", "") || ""
    when "reviewed?" then resp.reviewed? ? "Yes" : "No"
    when "place" then resp.place ? resp.place.full_name : ""
    when "actions"
      links = []
      # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
      # the controller actions will still be auth'd
      links << link_to_if_auth("Edit", edit_response_path(resp), "responses#update", resp)
      links << link_to_if_auth("Delete", resp, "responses#destroy", resp, :method => :delete, 
        :confirm => "Are you sure you want to delete that response?")
      join_links(*links)
    else resp.send(field)
    end
  end
  # calls the answer fields template for the given response
  def question_fields(resp)
    render("responses/questionings", :resp => resp)
  end
end
