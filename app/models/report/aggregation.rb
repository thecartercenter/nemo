class Report::Aggregation < ActiveRecord::Base
  belongs_to(:report, :class_name => "Report::Report")
  
  def apply(field, expr)
    code.gsub("?", expr)
  end
end
