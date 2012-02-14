require 'seedable'
class Report::Aggregation < ActiveRecord::Base
  include Seedable
  
  belongs_to(:report, :class_name => "Report::Report")
  
  def self.generate
    seed(:name, :name => "Average", :code => "AVG(?)")
    seed(:name, :name => "Minimum", :code => "MIN(?)")
    seed(:name, :name => "Maximum", :code => "MAX(?)")
  end
  
  def apply(field, expr)
    code.gsub("?", expr)
  end
end
