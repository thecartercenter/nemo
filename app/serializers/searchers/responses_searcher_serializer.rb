# frozen_string_literal: true

module Searchers
  # Serializes a ResponsesSearcher for search filters.
  class ResponsesSearcherSerializer < SearcherSerializer
    attributes :all_forms, :selected_form_ids, :selected_qings, :is_reviewed,
      :selected_users, :selected_groups

    def all_forms
      Form.for_mission(@current_mission)
        .map { |item| {name: item.name, id: item.id} }
        .sort_by_key || []
    end

    def selected_form_ids
      # NoopSearcher doesn't know about these types.
      object.try(:form_ids) || []
    end

    def selected_qings
      object.try(:qings) || []
    end

    def is_reviewed
      object.try(:is_reviewed)
    end

    def selected_users
      object.try(:submitters) || []
    end

    def selected_groups
      object.try(:groups) || []
    end

    def advanced_search_text
      (Settings.filters_beta.present? ? object.advanced_text : object.query) || ""
    end
  end
end
