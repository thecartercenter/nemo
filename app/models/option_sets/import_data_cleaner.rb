# frozen_string_literal: true

module OptionSets
  # Cleans data from spreadsheet for use in building option set.
  class ImportDataCleaner
    attr_accessor :file, :errors

    def initialize(file)
      self.file = file
      self.errors = []
    end

    def clean
      sheet = open_sheet || return
      headers = extract_headers(sheet)
      check_header_lengths(headers)
      special_columns = detect_special_columns(headers)
      rows = extract_and_clean_data_rows(sheet, headers, special_columns)

      if rows.empty?
        errors << [:no_rows]
      else
        special_columns.keys.reverse_each { |i| headers.delete_at(i) }
        [headers, special_columns, rows]
      end
    end

    private

    def open_sheet
      Roo::Spreadsheet.open(file).sheet(0)
    rescue TypeError, ArgumentError => error
      raise error unless /not an Excel 2007 file|Can't detect the type/.match?(error.to_s)
      errors << [:wrong_type]
      nil
    end

    def detect_special_columns(headers)
      special_headers = %i[coordinates shortcode].map { |k| I18n.t("activerecord.attributes.option.#{k}") }
      special_headers.unshift("Id")
      special_columns = {}
      headers.each_with_index do |h, i|
        special_columns[i] = h.downcase.to_sym if special_headers.include?(h)
      end
      special_columns
    end

    def extract_headers(sheet)
      headers = sheet.row(1)
      headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)
      headers
    end

    def check_header_lengths(headers)
      headers.each do |h|
        if h.size > OptionLevel::MAX_NAME_LENGTH
          errors << [:header_too_long, row_num: 1, limit: OptionLevel::MAX_NAME_LENGTH]
        end
      end
    end

    def check_option_lengths(row, row_num)
      row.each do |cell|
        if cell && cell.size > Option::MAX_NAME_LENGTH
          errors << [:option_too_long, row_num: row_num, limit: Option::MAX_NAME_LENGTH]
          return true
        end
      end
      false
    end

    def check_for_blank_interior_cells(row, row_num)
      # The portion of the array after the first nil should be all nils.
      return false if row.none?(&:nil?) || row[row.index(nil)..-1].all?(&:nil?)
      errors << [:blank_interior_cell, row_num: row_num]
      true
    end

    # Extracts data rows into an array of arrays.
    # The last element of each row's array is a hash of metadata like row_num
    # and special values like coordinates.
    def extract_and_clean_data_rows(sheet, headers, special_columns)
      (2..sheet.last_row).map do |row_num|
        row = sheet.row(row_num)[0...headers.size].map { |c| c.to_s.presence }

        metadata = extract_row_metadata(row, row_num, special_columns)

        next if row.all?(&:blank?)
        next if check_option_lengths(row, row_num)
        next if check_for_blank_interior_cells(row, row_num)

        row << metadata
      end
    end

    def extract_row_metadata(row, row_num, special_columns)
      metadata = {orig_row_num: row_num}
      special_columns.keys.reverse_each do |col_idx|
        metadata[special_columns[col_idx]] = row.delete_at(col_idx)
      end
      metadata
    end
  end
end
