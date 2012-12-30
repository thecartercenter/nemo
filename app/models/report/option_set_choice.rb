class Report::OptionSetChoice < ActiveRecord::Base
  belongs_to(:option_set)
  belongs_to(:report_report)
end
