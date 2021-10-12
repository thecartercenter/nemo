# frozen_string_literal: true

module Questions
  # Cleans data from a spreadsheet for use in building Questions.
  class ImportDataCleaner
    MIN_HEADERS = 4

    attr_accessor :sheet, :errors

    def initialize(sheet)
      self.sheet = sheet
      self.errors = []
    end

    def clean
      headers = extract_headers(sheet)
      rows = extract_and_clean_data_rows(sheet, headers)
      languages = detect_translations(headers)

      if rows.empty?
        errors << [:no_rows]
      else
        [languages, rows]
      end
    end

    private

    def extract_headers(sheet)
      headers = sheet[0]
      headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)
      errors << [I18n.t("question_import.errors.missing_headers")] if headers.count < MIN_HEADERS
      headers
    end

    # Extracts data rows into an array of arrays.
    # The last element of each row's array is a hash of metadata like row_num
    # and special values like coordinates.
    def extract_and_clean_data_rows(sheet, headers)
      sheet[1..].each.map do |row|
        row = row[0...headers.size].map { |c| c.to_s.presence }
        next if row.all?(&:blank?)
        row
      end.compact
    end

    def detect_translations(headers)
      languages = []
      headers.each do |h|
        language = h.match(/\[(\w+)\]\Z/)
        languages << language[1] if language.present?
      end
      languages.uniq
    end
  end
end
