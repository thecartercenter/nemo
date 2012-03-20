class Report::Grouping < ActiveRecord::Base
  
  # returns a combined set of select options for both answer and attrib groupings
  def self.select_options
    [Report::ByAttribGrouping, Report::ByAnswerGrouping].map{|k| [k.select_group_name, k.select_options]}
  end
  
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
      name = row[col_name]
      value = row[value_col_name] || row[col_name]
      {:name => name, :value => value}
    end.uniq.sort_by{|x| x[:value] || ""}
  end
  
  def value_col_name
    "#{col_name}_value"
  end
end
