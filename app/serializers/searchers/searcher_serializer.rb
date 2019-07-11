# frozen_string_literal: true

module Searchers
  class SearcherSerializer < ApplicationSerializer
    attributes :advanced_search_text

    format_keys :lower_camel

    def advanced_search_text
      (Settings.filters_beta.present? ? object.advanced_text : object.query) || ""
    end
  end
end
