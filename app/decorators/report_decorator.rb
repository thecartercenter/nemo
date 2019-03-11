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
end
