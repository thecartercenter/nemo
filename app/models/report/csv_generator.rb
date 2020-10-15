# frozen_string_literal: true

module Report
  # Generates CSV for a report.
  class CSVGenerator
    include ActiveModel::Model

    attr_accessor :report

    def to_csv
      UserFacingCSV.generate do |csv|
        # determine if we need blank cell for row headers
        blank = report.header_set[:row] ? [""] : []

        # add header row
        csv << blank + report.header_set[:col].collect { |c| c.name || "NULL" } if report.header_set[:col]

        # add data rows
        report.data.rows.each_with_index do |row, idx|
          # get row header if exists
          write_row(csv, row, idx)
        end
      end
    end

    private

    # Formats paragraph style textual data in CSV to play nice with Excel.
    def format_csv_para_text(text)
      return text unless text.is_a?(String) && text.present?

      # We convert to Markdown since there is a gem to do it and it's much more
      # readable. Conversion also strips unknown tags.
      text = ReverseMarkdown.convert(text, unknown_tags: :drop)

      # Excel seems to like \r\n, so replace all plain \ns with \r\n in all string-type cells.
      # Also ReverseMarkdown adds extra whitespace -- trim it.
      text = text.split(/\r?\n/).map(&:strip).join("\r\n")

      # Also remove html entities.
      text.gsub(/&(?:[a-z\d]+|#\d+|#x[a-f\d]+);/i, "")
    end

    def write_row(csv, row, idx)
      row_header = report.header_set[:row] ? [report.header_set[:row].cells[idx].name || "NULL"] : []

      # Add the data. All report data has the potential to be paragraph style text so we run it through
      # the formatter.
      csv << row_header + row.map { |c| format_csv_para_text(c) }
    end
  end
end
