# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: report_option_set_choices
#
#  id               :uuid             not null, primary key
#  option_set_id    :uuid             not null
#  report_report_id :uuid             not null
#
# Indexes
#
#  index_report_option_set_choices_on_option_set_id     (option_set_id)
#  index_report_option_set_choices_on_report_report_id  (report_report_id)
#  report_option_set_choice_unique                      (option_set_id,report_report_id) UNIQUE
#
# Foreign Keys
#
#  report_option_set_choices_option_set_id_fkey     (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#  report_option_set_choices_report_report_id_fkey  (report_report_id => report_reports.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class Report::OptionSetChoice < ApplicationRecord
  belongs_to(:option_set, inverse_of: :report_option_set_choices)
  belongs_to(:report, class_name: "Report::Report", foreign_key: "report_report_id",
                      inverse_of: :option_set_choices)

  # Called by OptionSet on destroy
  def option_set_destroyed
    destroy
    report.option_set_destroyed
  end
end
