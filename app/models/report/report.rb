require 'mission_based'
class Report::Report < ActiveRecord::Base
  include MissionBased

  belongs_to(:filter, :class_name => "Search::Search", :autosave => true, :dependent => :destroy)

  scope(:by_viewed_at, order("viewed_at desc"))
  scope(:by_popularity, order("view_count desc"))

  attr_reader :header_set, :data, :totals

  # validation is all handled client-side
  
  @@per_page = 20
  
  # generates a new report with a default name that won't collide with any existing names, 
  # in case the user decides not to choose a descriptive name
  def self.new_with_default_name(mission)
    prefix = "New Report"
    
    # get next number
    nums = for_mission(mission).where("name LIKE '#{prefix}%'").collect do |r| 
      # get suffix
      if r.name.match(/^#{prefix}(\s+\d+$|$)/)
        [$1.to_i, 1].max # must be at least one if found
      else
        1
      end
    end
    next_num = (nums.compact.max || 0) + 1
    suffix = next_num == 1 ? "" : " #{next_num}"

    for_mission(mission).new(:name => "#{prefix}#{suffix}")
  end

  # whether or not the report has been run yet
  def has_run?
    @has_run ||= !new_record?
  end
  
  # runs the report by populating header_set, data, and totals objects
  def run
    # set the has run flag
    @has_run = true
  
    # prep the relation and add a filter clause
    rel = prep_relation(Response.unscoped.for_mission(mission))
  
    # execute it the relation, returning rows, and create dbresult obj
    @db_result = Report::DbResult.new(rel.all)
    
    # extract headers
    @header_set = Report::HeaderSet.new(:row => get_row_header, :col => get_col_header)
    
    # extract data
    @data = Report::Data.new(@header_set.blank_data_table)
    @db_result.rows.each_with_index do |row, row_idx|
      extract_data_from_row(row, row_idx)
    end
    
    # compute totals if appropriate
    @data.compute_totals if can_total?
  end
  
  # form assignment helper for filter
  def filter_attributes=(attribs)
    self.filter = attribs[:str].blank? ? nil : Search::Search.new(attribs)
  end
  
  # records a viewing of the form, keeping the view_count up to date
  def record_viewing
    self.viewed_at = Time.now
    self.view_count += 1
    save(:validate => false)
  end
  
  protected
    # adds the given array of joins to the given relation by using the Join class
    def add_joins_to_relation(rel, joins)
      return rel.joins(Report::Join.list_to_sql(joins))
    end
end