# frozen_string_literal: true

module OptionSets
  # Cleans data from a spreadsheet for use in building an OptionSet.
  class ImportDataCleaner
    attr_accessor :sheet, :errors

    def initialize(sheet)
      self.sheet = sheet
      self.errors = []
    end

    def clean
      headers = extract_headers(sheet)
      check_header_lengths(headers)
      meta_headers = detect_meta_headers(headers)
      rows = extract_and_clean_data_rows(sheet, headers, meta_headers)

      if rows.empty?
        errors << [:no_rows]
      else
        # Remove the meta headers from the main headers.
        meta_headers.keys.reverse_each { |i| headers.delete_at(i) }
        [headers, meta_headers, rows]
      end
    end

    private

    # Returns a hash of form {0 => :id, 3 => :coordinates, ...}, mapping column indices to
    # the names of meta headers like Coordinates and Shortcode.
    def detect_meta_headers(headers)
      special_headers = %i[coordinates shortcode].map { |k| I18n.t("activerecord.attributes.option.#{k}") }
      special_headers.unshift("Id")
      meta_headers = {}
      headers.each_with_index do |h, i|
        meta_headers[i] = h.downcase.to_sym if special_headers.include?(h)
      end
      meta_headers
    end

    def extract_headers(sheet)
      headers = sheet[0]
      headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)
      headers
    end

    def check_header_lengths(headers)
      headers.each do |h|
        if h.size > OptionLevel::MAX_NAME_LENGTH
          errors << [:header_too_long, {row_num: 1, limit: OptionLevel::MAX_NAME_LENGTH}]
        end
      end
    end

    def check_option_lengths(row, row_num)
      row.each do |cell|
        if cell && cell.size > Option::MAX_NAME_LENGTH
          errors << [:option_too_long, {row_num: row_num, limit: Option::MAX_NAME_LENGTH}]
          return true
        end
      end
      false
    end

    def check_for_blank_interior_cells(row, row_num)
      # The portion of the array after the first nil should be all nils.
      return false if row.none?(&:nil?) || row[row.index(nil)..-1].all?(&:nil?)
      errors << [:blank_interior_cell, {row_num: row_num}]
      true
    end

    # Extracts data rows into an array of arrays.
    # The last element of each row's array is a hash of metadata like row_num
    # and special values like coordinates.
    def extract_and_clean_data_rows(sheet, headers, meta_headers)
      sheet[1..].each_with_index.map do |row, row_num|
        row = row[0...headers.size].map { |c| c.to_s.presence }
        row_num += 2 # Account for 0-index and header row.

        metadata = extract_row_metadata(row, row_num, meta_headers)

        next if row.all?(&:blank?)
        next if check_option_lengths(row, row_num)
        next if check_for_blank_interior_cells(row, row_num)

        row << metadata
      end.compact
    end

    def extract_row_metadata(row, row_num, meta_headers)
      metadata = {orig_row_num: row_num}
      meta_headers.keys.reverse_each do |col_idx|
        metadata[meta_headers[col_idx]] = row.delete_at(col_idx)
      end
      metadata
    end
  end
end
