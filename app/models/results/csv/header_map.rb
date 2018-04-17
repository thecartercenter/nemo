# frozen_string_literal: true

module Results
  module Csv
    # Keeps track of what column index each named header is written to.
    class HeaderMap
      attr_accessor :map

      def initialize
        self.map = ActiveSupport::OrderedHash.new
      end

      # Returns the index the given header maps to.
      # If the header doesn't exist yet, adds it.
      def index_for(header)
        map[header] ||= map.size
      end

      def headers
        map.keys
      end
    end
  end
end
