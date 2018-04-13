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
      attr_accessor :max_depth, :changes, :prev_row

      def initialize(max_depth:)
        self.max_depth = max_depth
        self.prev_row = {}
      end

      # Returns the number of [subtracted, added] levels in the group path.
      # For example, if the previous path was [R1,[2,1],[4,2]]
      # and the current row is an answer for question 3 on the same response,
      # that means the path is changing from [R1,[2,1],[4,2]] to [R1], so there is a change of [-2,0].
      # More examples:
      #
      # Previous Qing    New Qing          Previous Path       New Path         Return Value
      # [2,1].[4,2].1    3                 [R1,[2,1],[4,2]]  [R1]               [-2,0]
      # [2,1].[4,2].1    [2,1].[4,2].2     [R1,[2,1],[4,2]]  [R1,[2,1],[4,2]]   [ 0,0]
      # [2,1].[4,2].1    [2,1].[4,3].1     [R1,[2,1],[4,2]]  [R1,[2,1],[4,3]]   [-1,1]
      # [2,1].[4,2].1    [2,1].5           [R1,[2,1],[4,2]]  [R1,[2,1]]         [-1,0]
      # [2,1].[4,2].1    [1,1].1           [R1,[2,1],[4,2]]  [R2,[1,1]]         [-2,1]
      # 1                [2,1].[4,2].1     [R1]              [R1,[2,1],[4,2]]   [ 0,2]
      def process_row(row)
        # We use an ivar to avoid allocating new arrays constantly.
        self.changes = [0, 0]
        keys_to_check.each do |keys|
          # If chunk is nil in previous and current paths, do nothing.
          next if prev_row[keys[0]].nil? && row[keys[0]].nil?

          # If chunk identical in both paths
          if prev_row[keys[0]] == row[keys[0]] && prev_row[keys[1]] == row[keys[1]]
            # If there have been any changes so far, bump both additions and subtractions.
            if changed?
              changes[0] += 1
              changes[1] -= 1
            end
          else
            # From here on we know the chunks are different.
            # If chunk in new row is present, bump additions.
            # Also if chunk in old row is present, bump deletions.
            changes[1] += 1 if row[keys[0]].present?
            changes[0] -= 1 if prev_row[keys[0]].present?
          end
        end
        self.prev_row = row
        changes
      end

      def changed?
        !changes.nil? && (changes[0] != 0 || changes[1] != 0)
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

      # Gets keys in row to check for path data
      def keys_to_check
        # We include nil with response_id so that all chunk positions have a pair of elements.
        # This simplifies the main code.
        @keys_to_check ||= [["response_id", nil]] + (1..max_depth).to_a.map do |i|
          ["group#{i}_rank", "group#{i}_inst_num"]
        end
      end
    end
  end
end
