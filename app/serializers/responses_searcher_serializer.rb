# frozen_string_literal: true

# Serializes a ResponsesSearcher for search filters.
class ResponsesSearcherSerializer < SearcherSerializer
  fields :all_forms, :is_reviewed, :start_date, :end_date

  field :selected_form_ids do |object|
    object.form_ids || []
  end

  field :selected_qings do |object|
    object.qings || []
  end

  field :selected_users do |object|
    object.submitters || []
  end

  field :selected_groups do |object|
    object.groups || []
  end

  field :advanced_search_text do |object|
    object.advanced_text || ""
  end
end
