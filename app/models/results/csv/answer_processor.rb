# frozen_string_literal: true

module Results
  module Csv
    # Responsible for converting DB result rows into calls to buffer.write with appropriate
    # header names. Expects the following columns in the passed rows:
    # - question_code
    # - value
    # - time_value
    # - date_value
    # - datetime_value
    # - latitude
    # - longitude
    # - altitude
    # - accuracy
    # - answer_option_name
    # - choice_option_name
    # - option_level_name
    class AnswerProcessor
      attr_accessor :buffer, :row

      LOCATION_COLS = %w[latitude longitude altitude accuracy].freeze
      VALUE_COLS = %w[value time_value date_value datetime_value].freeze

      def initialize(buffer)
        self.buffer = buffer
      end

      def process(row)
        self.row = row
        write_select_cells if select_cols?
        write_location_cells if location_cols?
        write_value unless select_cols? || location_cols?
      end

      private

      def code
        row["question_code"]
      end

      def select_cols?
        row["answer_option_name"].present? || row["choice_option_name"].present?
      end

      def location_cols?
        LOCATION_COLS.any? { |c| row[c].present? }
      end

      # Writes all four location values with appropriate header.
      def write_location_cells
        LOCATION_COLS.each do |c|
          suffix = I18n.t("response.csv_headers.#{c}")
          buffer.write("#{code}:#{suffix}", row[c]) if row[c].present?
        end
      end

      def write_select_cells
        if row["answer_option_name"].present?
          suffix = (level = row["option_level_name"]) ? ":#{level}" : ""
          value = row["answer_option_name"]
          unless row["answer_option_value"].nil?
            value = row["answer_option_value"]
          end
          buffer.write("#{code}#{suffix}", value)
        else # select multiple
          buffer.write(code, row["choice_option_name"], append: true)
        end
      end

      # Writes the first non-blank column in VALUE_COLS.
      def write_value
        VALUE_COLS.each do |c|
          next if row[c].blank?
          convert_line_endings(row[c]) if c == "value"
          buffer.write(code, row[c])
          break
        end
      end

      def convert_line_endings(str)
        # We do this with loops instead of regexps b/c regexps are slow.
        convert_unix_line_endings_to_windows(str)
        convert_mac_line_endings_to_windows(str)
      end

      def convert_unix_line_endings_to_windows(str)
        # Insert \r before any \ns without \rs before
        offset = 0
        loop do
          idx = str.index("\n", offset)
          break if idx.nil?
          offset = idx + 1
          if idx.zero? || str[idx - 1] != "\r"
            str.insert(idx, "\r")
            offset += 1
          end
        end
      end

      def convert_mac_line_endings_to_windows(str)
        # Insert \n after any \rs without \ns after
        offset = 0
        loop do
          idx = str.index("\r", offset)
          break if idx.nil?
          offset = idx + 1
          if str[idx + 1] != "\n"
            str.insert(idx + 1, "\n")
            offset += 1
          end
        end
      end
    end
  end
end
