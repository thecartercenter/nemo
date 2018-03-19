# frozen_string_literal: true

module Results
  # Temporarily holds a set of rows from the CSV output while they are being populated.
  module Csv
    class Buffer
      attr_accessor :cells, :header_map, :empty
      alias empty? empty

      def initialize
        init_header_map
        self.cells = []
        self.empty = true
      end

      # Takes a row from the DB result and sets the appropriate cells in the buffer.
      def process_row(row)
        add_common_cells(row) if empty?
        header = row["question_code"]
        cells[col_index_for_header(header)] = row["answer_value"]
      end

      def dump_to(csv)
        return if empty?
        csv << cells
        clear
      end

      def headers
        # Translate the common headers and join to the per-question ones.
        common_header_names.map { |h| I18n.t("response.csv_headers.#{h}") }.concat(
          header_map.keys[common_header_names.size..-1])
      end

      private

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
