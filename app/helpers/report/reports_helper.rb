# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
module Report::ReportsHelper
  def report_reports_index_links(reports)
    links = [link_to_if_auth("Create new report", new_report_report_path, "report_reports#create")]
  end
  def report_reports_index_fields
    %w[title kind last_viewed views actions]
  end
  def format_report_reports_field(report, field)
    case field
    when "title" then link_to(report.name, report_report_path(report))
    when "last_viewed" then report.viewed_at && time_ago_in_words(report.viewed_at) + " ago"
    when "views" then report.view_count
    when "actions"
      action_links(report, :destroy_warning => "Are you sure you want to delete the report '#{report.name}'?")
    else report.send(field)
    end
  end
  def view_report_report_mini_form
    form_tag("/", :onsubmit => "window.location.href = '/report/reports/' + this.rid.options[this.rid.selectedIndex].value; return false;") do
      select_tag(:rid, options_for_select(Report::Report.select_options), :include_blank => true) + submit_tag("Go")
    end
  end
  
end
