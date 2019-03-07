# frozen_string_literal: true

class ReportDecorator < ApplicationDecorator
  delegate_all

  def default_path
    @default_path ||= h.report_path(object)
  end
end
