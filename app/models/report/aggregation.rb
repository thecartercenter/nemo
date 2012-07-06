require 'seedable'
class Report::Aggregation < ActiveRecord::Base
  include Seedable
  
  belongs_to(:report, :class_name => "Report::Report")
  
  def self.generate
    seed(:name, :name => "Tally", :code => "COUNT(?)")
    seed(:name, :name => "Average", :code => "AVG(?)")
    seed(:name, :name => "Sum", :code => "SUM(?)")
    seed(:name, :name => "Minimum", :code => "MIN(?)")
    seed(:name, :name => "Maximum", :code => "MAX(?)")
    seed(:name, :name => "List", :code => "?")
  end
  
  def self.select_options
    all.collect{|a| [a.name, a.id]}
  end
  
  def encode(expr)
    code.gsub("?", expr)
  end
  
  def is_tally?
    name == "Tally"
  end
  
  def is_list?
    name == "List"
  end
  
  # converts a result returned from the database to an appropriate object
  def cast_result_value(obj, fieldlet = nil)
    # if fieldlet is a datetime, need to adjust timezone
    if fieldlet && fieldlet.temporal?
      t = Time.zone.parse(obj.to_s + (fieldlet.has_timezone? ? " UTC" : ""))
      obj = t.to_s(:"std_#{fieldlet.data_type}")
    else
      # for a tally report, the result will be a string and should be an integer
      if is_tally?
        obj.to_i
      # for average reports, it should always be float
      elsif name == "Average"
        obj.to_f.round(1)
      # for list reports, should already be casted properly
      elsif name == "List"
        obj
      # for sum, min, and max, it depends on the field type
      else
        # for attrib type fields, it should already be casted properly, unless it's a time/date
        if fieldlet.is_a?(Report::ResponseAttribute)
          obj
        # for question type fields, it depends on the question type
        else
          case fieldlet.question.type.name
          when "integer" then obj.to_i
          when "decimal" then obj.to_f.round(1)
          else obj.to_s
          end
        end
      end
    end
  end
  
  # whether it makes sense to compute a total over this aggregation
  def can_total?
    %w(Tally Sum).include?(name)
  end
  
  def crosstab_format?
    name == "List"
  end
end
