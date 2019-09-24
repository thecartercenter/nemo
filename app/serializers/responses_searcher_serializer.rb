# frozen_string_literal: true

# Serializes a ResponsesSearcher for search filters.
class ResponsesSearcherSerializer < SearcherSerializer
  attributes :all_forms, :selected_form_ids, :selected_qings, :is_reviewed,
    :selected_users, :selected_groups, :start_date, :end_date

  def selected_form_ids
    object.form_ids || []
  end

  def selected_qings
    object.qings || []
  end

  def selected_users
    object.submitters || []
  end

  def selected_groups
    object.groups || []
  end

  def advanced_search_text
    object.advanced_text || ""
  end
end
