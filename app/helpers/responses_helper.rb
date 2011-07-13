module ResponsesHelper
  def format_responses_field(resp, field)
    case field
    when "date_submitted" then resp.created_at && resp.created_at.strftime("%Y-%b-%d %T") || ""
    when "age" then resp.created_at && time_ago_in_words(resp.created_at).gsub("about ", "") || ""
    when "reviewed?" then resp.reviewed? ? "Yes" : "No"
    when "actions"
      links = []
      links << link_to_if_auth("Edit", edit_response_path(resp), "responses#update", resp)
      links << link_to_if_auth("Delete", resp, "responses#destroy", resp,
        :method => :delete, :confirm => "Are you sure you want to delete that response?")
      join_links(*links)
    else resp.send(field)
    end
  end
end
