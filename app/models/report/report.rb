class Report::Report < ActiveRecord::Base
  belongs_to(:pri_grouping, :class_name => "Report::Grouping", :autosave => true, :dependent => :destroy)
  belongs_to(:sec_grouping, :class_name => "Report::Grouping", :autosave => true, :dependent => :destroy)
  belongs_to(:aggregation)
  belongs_to(:calculation)
  belongs_to(:filter, :class_name => "Search::Search", :autosave => true, :dependent => :destroy)
  has_many(:fields, :class_name => "Report::Field", :foreign_key => "report_report_id")
  
  attr_reader(:headers, :data)
  # NEED TO CONVERT THESE TO HAS_ONE RELATIONS
  # (ADD REPORT_REPORT_ID FIELDS TO SEARCH AND GROUPING)
  # OR MAYBE ONLY DO THIS WITH GROUPING
  accepts_nested_attributes_for(:filter)

  validates(:kind, :presence => true)
  validates(:name, :presence => true, :uniqueness => true)

  KINDS = ["Response Count"]
  
  def self.type_select_options
    KINDS
  end

  def pri_grouping_attributes=(attribs)
    self.pri_grouping = Report::Grouping.construct(attribs)
  end

  def sec_grouping_attributes=(attribs)
    self.sec_grouping = Report::Grouping.construct(attribs)
  end

  def run
    @rel = Response.unscoped
    
    # add groupings
    groupings.each{|g| @rel = g.apply(@rel)}
    
    # add count
    @rel = @rel.select("COUNT(responses.id) as `Count`")
    
    # apply filter
    @rel = filter.apply(@rel) unless filter.nil?
    
    # get data and headers
    results = @rel.all
    if groupings.empty?
      @headers = {:row => [""], :col => ["# Reports"]}
      @data = [results.first.attributes.values]
    else
      @headers = {
        :row => results.collect{|row| row[pri_grouping.col_name]}.uniq,
        :col => sec_grouping ? results.collect{|row| row[sec_grouping.col_name]}.uniq : ["# Reports"]
      }
      # create blank data table
      @data = @headers[:row].collect{|r| Array.new(@headers[:col].size)}

      # populate data table
      results.each do |row|
        r = @headers[:row].index(row[pri_grouping.col_name])
        c = sec_grouping ? @headers[:col].index(row[sec_grouping.col_name]) : 0
        @data[r][c] = row["Count"]
      end
    end
  end
  
  protected
    def groupings
      [pri_grouping, sec_grouping].compact
    end
end
