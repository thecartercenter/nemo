# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links for a report.
  class ReportLinkBuilder < LinkBuilder
    def initialize(report)
      actions = %i[show edit]
      actions << [:export, h.report_path(report, format: :csv)] if report.persisted? && report.exportable?
      actions << :destroy
      super(report.becomes(Report::Report), actions, controller: "reports")
    end
  end
end
