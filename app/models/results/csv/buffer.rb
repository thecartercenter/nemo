# frozen_string_literal: true

module Results
  module Csv
    # Temporarily holds the next row of the CSV output while it is being populated.
    # Responsible for preparing the row to receive new answer data by copying common data
    # (response data and parent group data) from the previous row of the CSV output.
    # Also responsible for dumping rows to the CSV handler when it's time to start a fresh row.
    class Buffer
      attr_accessor :csv, :cells, :header_map, :empty, :group_path,
        :max_depth, :column_stack
      alias empty? empty

      def initialize(max_depth:, header_map:)
        self.group_path = GroupPath.new(max_depth: max_depth)
        self.cells = []
        self.empty = true
        self.max_depth = max_depth
        self.header_map = header_map
        self.column_stack = ColumnStack.new
      end

      # Takes a row from the DB result and prepares the buffer for new data.
      # Dumps the row when appropriate (i.e. when the group path changes).
      def process_row(row)
        group_path.process_row(row)

        # If path to group has changed, it's time to dump the CSV row and start a new one!
        # (The first time through, the group path will have changed, but the row will be empty,
        # so nothing will be dumped.)
        dump_row if group_path.changed?

        # Now handle deletions and additions.
        handle_group_path_deletions if group_path.deletions?
        handle_group_path_additions(row) if group_path.additions?
      end

      # Writes the given value to the cell. If the cell already has something in it, appends.
      # This is useful for select_multiple. We don't need to worry about old data since
      # we clear it out in `process_row`.
      def write(header, value, append: false)
        self.empty = false
        idx = header_map.index_for(header)
        cells[idx] = cells[idx].present? && append ? "#{cells[idx]};#{value}" : value
        column_stack.add(idx)
      end

      def finish
        dump_row
      end

      private

      def handle_group_path_deletions
        column_stack.pop(group_path.deletion_count).each do |cols|
          cols.each { |i| clear_at(i) }
        end
        self.empty = column_stack.empty?
      end

      def handle_group_path_additions(row)
        group_path.addition_count.times do
          # If depth is 0, we are pushing the first frame on the stack, so we should write
          # the common headers to get the row started.
          # Else we just need to write the group rank and inst_num.
          depth = column_stack.size
          column_stack.push_empty_frame
          if depth.zero?
            write_common_columns(row)
          else
            write_group_info(row, depth)
          end
        end
      end

      def clear_at(idx)
        cells[idx] = nil
      end

      def write_group_info(row, depth)
        copy_from_row(row, "group#{depth}_rank")
        copy_from_row(row, "group#{depth}_inst_num")
      end

      def write_common_columns(row)
        header_map.common.each { |h| copy_from_row(row, h) }
      end

      def copy_from_row(row, header)
        write(header, row[header])
      end

      def dump_row
        return if empty?
        csv << cells
      end
    end
  end
end
