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
        row["option_name"].present? || row["choice_name"].present?
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
        if row["option_name"].present?
          suffix = (level = row["option_level_name"]) ? ":#{level}" : ""
          buffer.write("#{code}#{suffix}", row["option_name"])
        else # select multiple
          buffer.write(code, row["choice_name"], append: true)
        end
      end

      # Writes the first non-blank column in VALUE_COLS.
      def write_value
        VALUE_COLS.each do |c|
          next if row[c].blank?
          buffer.write(code, row[c])
          break
        end
      end
    end
  end
end
