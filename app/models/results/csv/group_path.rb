# frozen_string_literal: true

module Results
  module Csv
    # Tracks the current group path as we traverse the list of answer rows.
    # The group path is defined as the response ID plus pairs of [group rank, group item num] for each
    # parent group of a given answer. So a path of: [R1,[2,1],[4,2]] means the current answer is in:
    # - Response ID 1
    # - Item #1 of Group 2
    # - Item #2 of Group 2.4
    class GroupPath
      attr_accessor :changes

      def initialize
        self.prev_row = {}
        self.changes = [0, 0]
      end

      def process_row(row)
        changes[0] = 0
        changes[1] = 0
        check_for_changes_in_ancestry(prev_row["ancestry"], row["ancestry"])
        if prev_row["response_id"] != row["response_id"]
          changes[0] -= 1 unless prev_row.empty?
          changes[1] += 1
        end
        self.prev_row = row
      end

      def changed?
        changes[0] != 0 || changes[1] != 0
      end

      def addition_count
        changes[1]
      end

      def deletion_count
        -changes[0]
      end

      def additions?
        addition_count.positive?
      end

      def deletions?
        deletion_count.positive?
      end

      private

      attr_accessor :prev_row

      def check_for_changes_in_ancestry(*strs)
        diff = false
        strs[0] ||= "{AnswerGroup0}"
        pos = [1, 1]
        loop do
          tokens = [next_token(strs[0], pos[0]), next_token(strs[1], pos[1])]
          pos[0] += tokens[0].size + 1 if tokens[0]
          pos[1] += tokens[1].size + 1 if tokens[1]
          break if tokens[0].nil? && tokens[1].nil?
          next if !diff && tokens[0] == tokens[1]
          diff = true
          changes[0] -= 1 if tokens[0]&.start_with?("AnswerGroup") && !tokens[0].start_with?("AnswerGroupSet")
          changes[1] += 1 if tokens[1]&.start_with?("AnswerGroup") && !tokens[1].start_with?("AnswerGroupSet")
        end
      end

      # Gets the next comma delimited token from the given string, starting from the given offset.
      # Ignores last character in string.
      # Returns nil if no tokens found.
      def next_token(str, pos)
        str[pos...(str.index(",", pos) || -1)].presence
      end
    end
  end
end
