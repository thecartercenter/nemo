# frozen_string_literal: true

module Results
  # Temporarily holds a set of rows from the CSV output while they are being populated.
  module Csv
    class Buffer
      attr_accessor :csv, :cells, :header_map, :empty, :cur_group_path
      alias empty? empty

      def initialize
        init_header_map
        init_cur_group_path
        self.cells = []
        self.empty = true
      end

      # Takes a row from the DB result and sets the appropriate cells in the buffer.
      def process_row(row)
        # If path to group has changed, it's time to dump the CSV row and start a new one!
        dump_row if group_path_changed?(row)
        add_common_cells(row) if empty?
        header = row["question_code"]
        cells[col_index_for_header(header)] = row["answer_value"]
      end

      def finish
        dump_row
      end

      def headers
        # Translate the common headers and join to the per-question ones.
        common_header_names.map { |h| I18n.t("response.csv_headers.#{h}") }.concat(
          header_map.keys[common_header_names.size..-1])
      end

      private

      def dump_row
        return if empty?
        csv << cells
        clear
      end

      def init_cur_group_path
        # -1s ensure it will be changed on first loop.
        self.cur_group_path = group_path_keys.map { |key| [key, -1] }.to_h
      end

      # Keys/col names from a row that uniquely identify the row's group path.
      def group_path_keys
        @group_path_keys ||= %w[response_id group1_rank group1_item_num]
      end

      # Checks if the path to the group for the current answer row has changed from the previous row.
      def group_path_changed?(row)
        changed = false
        group_path_keys.each do |key|
          if row[key] != cur_group_path[key]
            changed = true
            cur_group_path[key] = row[key]
          end
        end
        changed
      end

      def init_header_map
        self.header_map = ActiveSupport::OrderedHash.new
        common_header_names.each_with_index do |name, i|
          header_map[name] = i
        end
      end

      def common_header_names
        @common_header_names ||= %w[response_id form_name user_name submit_time shortcode
          group1_rank group1_item_num parent_group_name parent_group_depth]
      end

      def col_index_for_header(header)
        header_map[header] ||= header_map.size
      end

      # Copies common cells from row into buffer.
      def add_common_cells(row)
        self.empty = false
        common_header_names.each { |name| cells[header_map[name]] = row[name] }
      end

      def clear
        cells.size.times { |i| cells[i] = nil }
        self.empty = true
      end
    end
  end
end
