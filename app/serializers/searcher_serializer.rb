# frozen_string_literal: true

class SearcherSerializer < ApplicationSerializer
  field :advanced_search_text do |object|
    # We can't assume advanced_text was actually parsed, so return the original query.
    object.query || ""
  end
end
