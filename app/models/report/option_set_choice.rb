class Report::OptionSetChoice < ActiveRecord::Base
  belongs_to(:option_set, inverse_of: :report_option_set_choices)
  belongs_to(:report, class_name: 'Report::Report', foreign_key: 'report_report_id', inverse_of: :option_set_choices)

  after_destroy { report.option_set_destroyed }
end
