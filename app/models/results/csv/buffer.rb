# frozen_string_literal: true

module Results
  module CSV
    # Temporarily holds the next row of the CSV output while it is being populated.
    # Responsible for preparing the row to receive new answer data by copying common data
    # (response data and parent group data) from the previous row of the CSV output.
    # Also responsible for dumping rows to the CSV handler when it's time to start a fresh row.
    class Buffer
      attr_accessor :csv, :output_rows, :header_map, :empty, :group_path,
        :applicable_rows_stack, :group_names

      delegate :empty?, to: :output_rows

      def initialize(header_map:)
        self.header_map = header_map
        self.group_path = GroupPath.new
        self.group_names = {}
        self.empty = true

        # Holds the rows we are currently collecting information for and waiting to write out to CSV.
        # These are all due to a single response. We dump the buffer each time we change responses.
        self.output_rows = []

        # A stack of frames (arrays) of indices of rows in the buffer.
        # Each frame represents a level of nesting.
        # The indices in the top-most frame on the stack correspond to rows that should be
        # written to when `write` is called.
        # It might look like [[0, 1, 2, 3], [2, 3], [3]] if we are in a doubly nested group.
        self.applicable_rows_stack = []
      end

      # Takes a row from the DB result and prepares the buffer for new data.
      # Dumps the row when appropriate (i.e. when the group path changes).
      def process_row(input_row)
        group_path.process_row(input_row)
        handle_group_path_deletions if group_path.deletions?
        handle_group_path_additions(input_row) if group_path.additions?
        write_group_name
      end

      # Writes the given value to the applicable rows in the buffer.
      # If a cell already has something in it and `append` is true, it appends (useful for select_multiple).
      # If the given header is not found, ignores.
      def write(header, value, append: false)
        col_idx = header_map.index_for(header)
        return if col_idx.nil?
        applicable_rows_stack.last.each do |row_idx|
          output_rows[row_idx][col_idx] =
            if (current = output_rows[row_idx][col_idx]).present? && append
              "#{current};#{value}"
            else
              value
            end
        end
      end

      def finish
        dump_rows
      end

      private

      def handle_group_path_deletions
        applicable_rows_stack.pop(group_path.deletion_count)
        dump_rows if applicable_rows_stack.empty?
      end

      def handle_group_path_additions(input_row)
        group_path.addition_count.times do
          add_row
          applicable_rows_stack.push([])
          # The new row we just added carries information from all levels currently represented
          # in the stack. So we write the row index to each frame in the stack.
          applicable_rows_stack.each { |r| r << output_rows.size - 1 }
          # If we just added the first row, we should write the common columns to get it started.
          # Subsequent output_rows will be cloned from this one so we only need to do it once.
          write_common_columns(input_row) if output_rows.size == 1
        end
      end

      def write_common_columns(input_row)
        header_map.common_headers.each { |h| write(h, input_row[h]) }
      end

      def write_group_name
        write_cell(row_for_current_level, "parent_group_name", current_group_name)
      end

      # Adds a row to the buffer by cloning the parent row, or if empty, adding a new blank row.
      def add_row
        new_row =
          if output_rows.any?
            row_for_current_level.dup
          else
            Array.new(header_map.count)
          end
        # We need to reset the group columns because they change each time. The rest of the columns
        # should be inherited from the parent column.
        write_cell(new_row, "parent_group_name", nil)
        write_cell(new_row, "parent_group_depth", applicable_rows_stack.size)
        output_rows << new_row
      end

      def row_for_current_level
        # The current row is the first index in the current stack frame. The rest of the indices in
        # the current stack frame come from rows for child levels.
        current_row_idx = applicable_rows_stack.last.first
        output_rows[current_row_idx]
      end

      def read_cell(row, col_name)
        row[header_map.index_for(col_name)]
      end

      def write_cell(row, col_name, value)
        return if row.nil?
        row[header_map.index_for(col_name)] = value
      end

      def dump_rows
        output_rows.each do |row|
          # No need to write rows that don't have any answers for their level, except we always
          # write a row for the top level of the response even if it has no answer data of its own.
          next if read_cell(row, "parent_group_depth").positive? && read_cell(row, "parent_group_name").nil?
          csv << row
        end
        output_rows.clear
      end

      def current_group_name
        group_id = group_path.parent_repeat_group_id
        return nil if group_id.nil?
        group_names[group_id] ||= (QingGroup.find_by(id: group_id)&.group_name || "?")
      end
    end
  end
end
