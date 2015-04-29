module Report::ReportsHelper
  require 'csv'

  def report_reports_index_links(reports)
    can?(:create, Report::Report) ? [create_link(Report::Report)] : []
  end

  def report_reports_index_fields
    %w(name type viewed_at view_count actions)
  end

  def format_report_reports_field(report, field)
    case field
    when "name" then link_to(report.name, report_path(report), :title => t("common.view"))
    when "type" then translate_model(report.class)
    when "viewed_at" then report.viewed_at && t("layout.time_ago", :time => time_ago_in_words(report.viewed_at))
    when "actions" then table_action_links(report.becomes(Report::Report))
    else report.send(field)
    end
  end

  # converts the given report to CSV format
  def report_to_csv(report)
    # We use \r\n because Excel seems to prefer it.
    CSV.generate(row_sep: "\r\n") do |csv|
      # determine if we need blank cell for row headers
      blank = report.header_set[:row] ? [""] : []

      # add header row
      if report.header_set[:col]
        csv << blank + report.header_set[:col].collect{|c| c.name || "NULL"}
      end

      # add data rows
      report.data.rows.each_with_index do |row, idx|
        # get row header if exists
        row_header = report.header_set[:row] ? [report.header_set[:row].cells[idx].name || "NULL"] : []

        # Add the data. All report data has the potential to be paragraph style text so we run it through
        # the formatter.
        csv << row_header + row.map{ |c| format_csv_para_text(c) }
      end
    end
  end

  # javascript includes for the report view
  def report_js_includes
    javascript_include_tag("https://www.google.com/jsapi") +
      javascript_tag('google.load("visualization", "1", {packages:["corechart"]});')
  end
end
