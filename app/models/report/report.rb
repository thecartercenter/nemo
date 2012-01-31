class Report::Report < ActiveRecord::Base
  belongs_to(:pri_grouping, :class_name => "Report::Grouping")
  belongs_to(:sec_grouping, :class_name => "Report::Grouping")
  belongs_to(:aggregation)
  belongs_to(:calculation)
  belongs_to(:filter, :class_name => "Search::Search")
  has_many(:fields, :class_name => "Report::Field", :foreign_key => "report_report_id")
  
  attr_reader(:headers, :data)

  TYPES = [{:name => "Response Count", :class_name => "ResponseCountReport"}]
  
  def self.type_select_options
    TYPES.collect{|t| [t[:name], t[:class_name]]}
  end
  
  # runs the report, setting the headers and data variables
 # def run
 #   @rel = Response.unscoped
 #   
 #   # add groupings
 #   groupings.each{|g| @rel = g.apply(@rel) unless g.nil?}
 #
 #   # add entries for fields
 #   fields.each{|f| @rel = f.apply(@rel)}
 #   
 #   # if no fields were added at all, raise report error
 #   raise Report::ReportError.new("No fields matched the specification") if @rel == Response.unscoped
 #   
 #   # add where clause from filter
 #   @rel = filter.apply(@rel) if filter
 #
 #   # get the rows
 #   result = @rel.all
 #   if result.empty?
 #     @data = []
 #     @headers = {}
 #   elsif result.first.attributes.keys.size == 1
 #     @data = [result.first.attributes.values]
 #     @headers = {:row => [result.first.attributes.keys.first], :col => []}
 #   elsif aggregation.nil?
 #     @data = result.collect{|row| row.attributes.values}
 #     @headers = {:row => [], :col => result.first.attributes.keys}
 #   elsif aggregation.name.match(/count/i)
 #     if groupings.compact.size == 1
 #       @data = result.collect{|row| [row.attributes["count"]]}
 #       @headers = {:row => result.collect{|row| row.attributes[groupings.compact[0].name]}, 
 #         :col => [groupings.compact[0].name, "Count"]}
 #     end
 #   elsif groupings.compact.size == 2
 #     @headers = {:row => result.collect{|row| row[pri_grouping.name]}.uniq,
 #       :col => result.collect{|row| row[sec_grouping.name]}.uniq}
 #     # create blank data table
 #     @data = @headers[:row].collect{|r| Array.new(@headers[:col].size)}
 #     # populate data table
 #     result.each do |row|
 #       r = @headers[:row].index(row[pri_grouping.name])
 #       c = @headers[:col].index(row[sec_grouping.name])
 #       @data[r][c] = row[fields.first.name]
 #     end
 #   elsif !aggregation.name.match(/count/i)
 #     if groupings.compact.empty?
 #       @data = result.first.attributes.collect{|key, value| [value]}
 #       @headers = {:row => result.first.attributes.collect{|key, value| [key]}, :col => []}
 #     end
 #   end
 # end

  protected
    def groupings
      [pri_grouping, sec_grouping].compact
    end
      
end
