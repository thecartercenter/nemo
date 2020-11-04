# frozen_string_literal: true

module Results
  module CSV
    # Tracks the current group path as we traverse the list of answer rows.
    # The group path is defined as the response ID plus pairs of [group rank, group item num] for each
    # parent group of a given answer. So a path of: [R1,[2,1],[4,2]] means the current answer is in:
    # - Response ID 1
    # - Item #1 of Group 2
    # - Item #2 of Group 2.4
    class GroupPath
      attr_accessor :changes, :parent_repeat_group_id

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

      # Scans through the two ancestry strings and looks for salient differences.
      def check_for_changes_in_ancestry(*strs)
        self.parent_repeat_group_id = nil
        diff = false
        strs[0] ||= "{AnswerGroup:0:00000000-0000-0000-0000-000000000000}"
        pos = [1, 1]
        tokens = [nil, nil]
        loop do
          prev_tokens = tokens
          tokens = [next_token(strs[0], pos[0]), next_token(strs[1], pos[1])]

          # If no tokens left in either string, we're done.
          break if tokens[0].nil? && tokens[1].nil?

          # Advance scan positions on both strings
          pos[0] += tokens[0].size + 1 if tokens[0]
          pos[1] += tokens[1].size + 1 if tokens[1]

          self.parent_repeat_group_id = tokens[1][-36..] if tokens[1]&.starts_with?("AnswerGroupSet")

          # If we haven't found any differences yet and these two tokens are the same,
          # we can proceed to next tokens.
          next if !diff && tokens[0] == tokens[1]

          # Otherwise we know we've encountered a difference.
          diff = true

          # Additions and subtractions to the path amount to the number of differing repeat AnswerGroups
          # in the two strings.
          changes[0] -= 1 if group_in_set?(tokens[0], prev_tokens[0])
          changes[1] += 1 if group_in_set?(tokens[1], prev_tokens[1])
        end
      end

      # Checks if the given token, assuming the given previous token, represents an AnswerGroup inside
      # an AnswerGroupSet.
      def group_in_set?(token, prev_token)
        return false if token.nil? || prev_token.nil?
        # If the new token is a group (not a group set) AND the previous token was a group set,
        # this is a group inside a repeat group.
        token.start_with?("AnswerGroup") && !token.start_with?("AnswerGroupSet") &&
          prev_token.start_with?("AnswerGroupSet")
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
