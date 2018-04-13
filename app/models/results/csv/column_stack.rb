# frozen_string_literal: true

require "set"

module Results
  module Csv
    # Keeps a stack of the indices of columns that should be shared between adjacent CSV rows.
    # Indices are grouped into frames (sets) which each represent a level of nesting.
    # So a typical state might be [{1, 2, 3, 4}, {5, 6, 7}, {10, 11}].
    # This would be for a doubly nested group.
    class ColumnStack
      attr_accessor :stack

      delegate :pop, :size, :empty?, to: :stack

      def initialize
        self.stack = []
      end

      # Adds a new index to the current stack frame.
      def add(idx)
        # Don't need to worry about duplicates thanks to Set data structure.
        stack.last << idx
      end

      def push_empty_frame
        stack.push(Set.new)
      end
    end
  end
end
