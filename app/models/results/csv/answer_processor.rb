# frozen_string_literal: true

module Results
  module CSV
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
      attr_accessor :buffer, :row, :long_text_behavior

      VALUE_COLS = %w[value time_value date_value datetime_value].freeze

      # Microsoft Excel limitations.
      MAX_NEWLINES = 254
      MAX_CHARACTERS = 32_767

      def initialize(buffer)
        self.buffer = buffer
      end

      def process(row, long_text_behavior: "include")
        self.row = row
        self.long_text_behavior = long_text_behavior
        write_select_cells if select_cols?
        write_location_cells if location_cols?
        write_value unless select_cols? || location_cols?
      end

      private

      def code
        row["question_code"]
      end

      def qtype
        row["qtype_name"]
      end

      def select_cols?
        row["answer_option_name"].present? || row["choice_option_name"].present?
      end

      def location_cols?
        Answer::LOCATION_COLS.any? { |c| row[c].present? }
      end

      # Writes all four location values with appropriate header.
      def write_location_cells
        Answer::LOCATION_COLS.each do |c|
          suffix = I18n.t("response.csv_headers.#{c}")
          buffer.write("#{code}:#{suffix}", row[c]) if row[c].present?
        end
      end

      def write_select_cells
        if row["answer_option_name"].present?
          suffix = (level = row["option_level_name"]) ? ":#{level}" : ""
          value = row["answer_option_value"] || row["answer_option_name"]
          buffer.write("#{code}#{suffix}", value)
        else # select multiple
          value = row["choice_option_value"] || row["choice_option_name"]
          buffer.write(code, value, append: true)
        end
      end

      # Writes the first non-blank column in VALUE_COLS.
      def write_value
        VALUE_COLS.each do |c|
          next if row[c].blank?
          normalize_value(row[c]) if c == "value"
          buffer.write(code, row[c])
          break
        end
      end

      # Performance-critical; try to do everything in-place.
      # We do this with loops instead of regexps b/c regexps are slow.
      def normalize_value(str)
        long_text = qtype == "long_text"
        if long_text && long_text_behavior == "exclude"
          str.slice!(0..-1)
          return
        end
        convert_unix_line_endings_to_windows(str)
        convert_mac_line_endings_to_windows(str)
        convert_long_text(str) if long_text
      end

      # Insert \r before any \ns without \rs before
      def convert_unix_line_endings_to_windows(str)
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

      # Insert \n after any \rs without \ns after
      def convert_mac_line_endings_to_windows(str)
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

      # Modify the string according to long_text_behavior.
      def convert_long_text(str)
        return if long_text_behavior == "include"

        if str.length > MAX_CHARACTERS
          str.slice!(MAX_CHARACTERS..-1)
          str.chomp! # Don't allow a dangling "\r" with no "\n".
        end

        trim_at_max_newlines(str)
      end

      # Assuming line endings have already been normalized,
      # count them and stop at the max.
      def trim_at_max_newlines(str)
        offset = 0
        count = 0
        loop do
          idx = str.index("\r\n", offset)
          return if idx.nil? # No more newlines and not yet at max, so it's good.
          if count >= MAX_NEWLINES # This newline sets it over the limit, so end before the newline.
            str.slice!(idx..-1)
            return
          end
          offset = idx + 1
          count += 1
        end
      end
    end
  end
end
