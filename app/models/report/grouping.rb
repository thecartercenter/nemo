class Report::Grouping < ActiveRecord::Base
  
  # returns a combined set of select options for both answer and attrib groupings
  def self.construct(attribs)
    return nil if attribs[:form_choice].blank?
    raise "Invalid grouping choice" unless attribs[:form_choice].match(/(by_answer|by_attrib)_(\d+)/)
    class_name = "Report::#{$1.camelize}Grouping"
    id = $2
    eval(class_name).new(:assoc_id => id)
  end
  
  # gets and sorts the full set header hashes based on the returned report results
  def headers(results)
    results.collect do |row|
      name = cast_header(row[sql_col_name])
      {
        :name => name,
        :value => row[value_col_name] || name,
        :key => name
      }
    end.uniq.sort_by{|x| x[:value] || ""}
  end
  
  def value_col_name
    "#{sql_col_name}_value"
  end
  
  def key(result_row)
    cast_header(result_row[sql_col_name])
  end
  
  def title
    to_s
  end
  
  def cast_header(value)
    if value.is_a?(Mysql::Time)
      value.to_s.gsub(" 00:00:00", "") 
    else
      value
    end
  end
end
