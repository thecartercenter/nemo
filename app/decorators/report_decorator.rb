# frozen_string_literal: true

class ReportDecorator < ApplicationDecorator
  delegate_all

  # Without this, if decorator.class is called, it returns the Report module for some reason.
  def class
    Report::Report
  end

  def default_path
    @default_path ||= h.report_path(object)
  end

  def to_csv
    UserFacingCSV.generate(row_sep: configatron.csv_row_separator) do |csv|
      # determine if we need blank cell for row headers
      blank = object.header_set[:row] ? [""] : []

      # add header row
      csv << blank + object.header_set[:col].collect { |c| c.name || "NULL" } if object.header_set[:col]

      # add data rows
      object.data.rows.each_with_index do |row, idx|
        # get row header if exists
        row_header = object.header_set[:row] ? [object.header_set[:row].cells[idx].name || "NULL"] : []

        # Add the data. All report data has the potential to be paragraph style text so we run it through
        # the formatter.
        csv << row_header + row.map { |c| format_csv_para_text(c) }
      end
    end
  end

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
end
