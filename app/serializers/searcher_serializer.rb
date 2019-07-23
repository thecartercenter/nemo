# frozen_string_literal: true

class SearcherSerializer < ApplicationSerializer
  attributes :advanced_search_text

  format_keys :lower_camel

  def advanced_search_text
    # We can't assume advanced_text was actually parsed, so return the original query.
    object.query || ""
  end
end
