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
    when "type" then translate_model(report.type)
    when "viewed_at" then report.viewed_at && t("layout.time_ago", time: time_ago_in_words(report.viewed_at))
    else report.send(field)
    end
  end

  # javascript includes for the report view
  def report_chart_js
    return "" if offline?
    javascript_include_tag("https://www.google.com/jsapi") +
      javascript_tag('if (typeof(google) != "undefined")
        google.load("visualization", "1", {packages:["corechart"]});')
  end

  def shortcode_map(response_ids)
    Response.where(id: response_ids).pluck(:id, :shortcode).to_h
  end
end
