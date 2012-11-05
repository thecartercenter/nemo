module Report::ReportsHelper
  def report_reports_index_links(reports)
    links = [link_to_if_auth("Create new report", new_report_report_path, "report_reports#create")]
  end
  def report_reports_index_fields
    %w[title last_viewed views actions]
  end
  def format_report_reports_field(report, field)
    case field
    when "title" then link_to(report.name, report_report_path(report))
    when "last_viewed" then report.viewed_at && time_ago_in_words(report.viewed_at) + " ago"
    when "views" then report.view_count
    when "actions"
      action_links(report, :destroy_warning => "Are you sure you want to delete the report '#{report.name}'?", :exclude => [:edit])
    else report.send(field)
    end
  end
  def view_report_report_mini_form
    form_tag("/") do
      select_tag(:rid, sel_opts_from_objs(@reports, :tags => true), :prompt => "Choose a Report...",
        :onchange => "window.location.href = '/report/reports/' + this.options[this.selectedIndex].value")
    end
  end
end
