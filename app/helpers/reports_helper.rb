# frozen_string_literal: true

module ReportsHelper
  def report_reports_index_links(_reports)
    can?(:create, Report::Report) ? [create_link(Report::Report)] : []
  end

  def report_reports_index_fields
    %w[name type viewed_at view_count]
  end

  def format_report_reports_field(report, field)
    case field
    when "name" then link_to(report.name, report.default_path, title: t("common.view"))
    when "type" then translate_model(report.class)
    when "viewed_at" then report.viewed_at && t("layout.time_ago", time: time_ago_in_words(report.viewed_at))
    else report.send(field)
    end
  end

  # converts the given report to CSV format
  def report_to_csv(report)
    # We use \r\n because Excel seems to prefer it.
    CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
      # determine if we need blank cell for row headers
      blank = report.header_set[:row] ? [""] : []

      # add header row
      csv << blank + report.header_set[:col].collect { |c| c.name || "NULL" } if report.header_set[:col]

      # add data rows
      report.data.rows.each_with_index do |row, idx|
        # get row header if exists
        row_header = report.header_set[:row] ? [report.header_set[:row].cells[idx].name || "NULL"] : []

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

  # javascript includes for the report view
  def report_js_includes
    javascript_include_tag("https://www.google.com/jsapi") +
      javascript_tag('if (typeof(google) != "undefined")
        google.load("visualization", "1", {packages:["corechart"]});')
  end
end
