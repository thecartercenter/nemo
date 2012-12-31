require 'mission_based'
class Report::Report < ActiveRecord::Base
  include MissionBased
  
  attr_accessible :type, :name, :option_set_id, :display_type, :bar_style, :unreviewed, 
    :question_labels, :show_question_labels, :percent_type, :unique_rows, :calculations_attributes, :calculations, 
    :option_set, :filter_attributes, :mission_id, :mission
  
  belongs_to(:filter, :class_name => "Search::Search", :autosave => true, :dependent => :destroy)

  scope(:by_viewed_at, order("viewed_at desc"))
  scope(:by_popularity, order("view_count desc"))

  before_save(:normalize_attribs)

  attr_accessor :just_created
  attr_reader :header_set, :data, :totals

  # validation is all handled client-side
  
  @@per_page = 20
  
  PERCENT_TYPES = [
    {:name => "", :label => "No Percentage"}, 
    {:name => :overall, :label => "Percentage Overall"}, 
    {:name => :by_row, :label => "Percentage By Row"},
    {:name => :by_col, :label => "Percentage By Column"}
  ]
  
  # HACK TO GET STI TO WORK WITH ACCEPTS_NESTED_ATTRIBUTES_FOR
  class << self
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and (klass = type.constantize) != self
        raise "wtF hax!!"  unless klass < self  # klass should be a descendant of us
        return klass.new(*a, &b)
      end

      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast
  end
  
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
    @data = Report::Data.new(blank_data_table(@db_result))
    @db_result.rows.each_with_index do |row, row_idx|
      extract_data_from_row(row, row_idx)
    end
    
    # clean out blank rows
    remove_blank_rows
    
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
  
  def as_json(options = {})
    h = super(options)
    h[:new_record] = new_record?
    h[:just_created] = just_created
    h[:type] = type
    h[:data] = @data
    h[:headers] = @header_set ? @header_set.headers : {}
    h[:filter_str] = filter ? filter.str : ""
    h[:can_total] = can_total?
    h
  end
  
  def can_total?
    # default to false, should be overridden
    false
  end
  
  protected
    # adds the given array of joins to the given relation by using the Join class
    def add_joins_to_relation(rel, joins)
      return rel.joins(Report::Join.list_to_sql(joins))
    end
    
    # builds a nested SQL IF statement of the form IF(a, x, IF(b, y, IF(c, z, ...)))
    def build_nested_if(exprs, conds, options = {})\
      unless options[:dont_optimize]
        # optimize by joining conditions for identical expressions
        # first build a hash
        expr_hash = {}
        exprs.each_with_index do |expr, i|
          expr_hash[expr] ||= []
          expr_hash[expr] << conds[i]
        end
      
        # rebuild condensed exprs and conds arrays
        exprs, conds = [], []
        expr_hash.each do |expr, cond_set|
          exprs << expr
          conds << cond_set.join(" OR ")
        end
      end
      
      if exprs.size == 1
        return exprs.first 
      else
        rest = build_nested_if(exprs[1..-1], conds[1..-1], :dont_optimize => true)
        "IF(#{conds.first}, #{exprs.first}, #{rest})"
      end
    end
    
    def normalize_attribs
      # we now do default values here as well as changing blanks to nils. 
      # the AR default stuff doesn't work b/c the blank from the client side overwrites the default and there's no easy way to get it back
      self.option_set_id = nil if option_set_id.blank?
      self.bar_style = "Side By Side" if bar_style.blank?
      self.display_type = "Table" if display_type.blank?
      self.percent_type = "" if percent_type.blank?
    end
    
    # by default we don't have to worry about blank rows
    def remove_blank_rows
    end
end