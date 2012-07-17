class Report::Report < ActiveRecord::Base
  belongs_to(:pri_grouping, :class_name => "Report::Grouping", :autosave => true, :dependent => :destroy)
  belongs_to(:sec_grouping, :class_name => "Report::Grouping", :autosave => true, :dependent => :destroy)
  belongs_to(:aggregation)
  belongs_to(:calculation)
  belongs_to(:filter, :class_name => "Search::Search", :autosave => true, :dependent => :destroy)
  has_many(:fields, :class_name => "Report::Field", :foreign_key => "report_report_id", :autosave => true, :dependent => :destroy)
  
  scope(:by_viewed_at, order("viewed_at desc"))
  scope(:by_popularity, order("view_count desc"))
  
  validates(:name, :presence => true, :uniqueness => true)
  validates(:aggregation, :presence => true)
  validates(:display_type, :presence => true)
  validate(:must_have_fields_unless_tally)
  
  DISPLAY_TYPES = ["Table"]
  BAR_STYLES = ["Side By Side", "Stacked"]
  PERCENT_TYPES = ["Percentage Overall"]
  
  attr_reader :data
  
  def self.display_type_select_options; DISPLAY_TYPES; end
  def self.bar_style_select_options; BAR_STYLES; end
  def self.percent_type_select_options; PERCENT_TYPES; end
  
  def self.select_options
    by_popularity.collect{|r| [r.name, r.id]}
  end
  
  def self.new_with_default_name
    prefix = "New Report"
    suffix = nn(where("name LIKE '#{prefix}%'").collect{|r| nn(nn(r.name.match(/^#{prefix}(\s+\d+$|$)/))[1]).to_i}.compact.max) + 1
    new(:name => "#{prefix} #{suffix == 1 ? 2 : suffix}")
  end
  
  # generates/returns a FieldSet object for this report
  def field_set
    @field_set ||= Report::FieldSet.new(fields)
  end
    
  # whether or not the report has been run yet
  def has_run?
    @has_run ||= !new_record?
  end
  
  def headers
    @header_set.headers
  end
    
  # form assignment helper
  def filter_attributes=(attribs)
    self.filter = attribs[:str].blank? ? nil : Search::Search.new(attribs)
  end
  
  # form assignment helper
  def pri_grouping_attributes=(attribs)
    self.pri_grouping = Report::Grouping.construct(attribs)
  end

  # form assignment helper
  def sec_grouping_attributes=(attribs)
    self.sec_grouping = Report::Grouping.construct(attribs)
  end
  
  # receives an array of field full_ids and has to update the fields associated with this object to match them
  def fields_attributes=(attribs)
    # match existing fields to submitted ones, with field full_id as comparator
    fields.match(attribs.reject{|f| f[:full_id].blank?}, Proc.new{|f| f[:full_id] || f.full_id}) do |orig, subd|
      # if original wasn't there, add the submitted
      if orig.nil?
        fields.build(subd)
      # if subd isn't there, delete the original
      elsif subd.nil?
        fields.destroy(orig)
      end
      # (if both exist, we don't need to do anything)
    end
  end
    
  # runs the report!
  def run
    # set the has run flag
    @has_run = true
    
    begin
      # prep the relation and get the results
      @results = prep_relation.all
    
      # check for nil result
      if @results.empty? || @results.size == 1 && @results.first.attributes.keys.include?("Value") && @results.first["Value"].nil?
        @data = nil
        return
      end
      
      # debug print results
      #@results.each{|row| pp row.attributes}
      
      # tally report
      if aggregation.is_tally?
      
        # row headers are from pri_grouping; col headers are from sec_grouping
        @header_set = Report::HeaderSet.new(@results, {:row => pri_grouping, :col => sec_grouping}, :default_name => "Tally")

        # get data
        @data = @header_set.blank_data_table
        @results.each_with_index do |row, row_idx|
          # get row and column indices by looking them up in the header list
          r, c = @header_set.find_indices(row, row_idx)

          # set the cell value
          @data[r][c] = aggregation.cast_result_value(row["Count"]) unless r.nil? || c.nil?
        end

        # totals
        compute_totals
    
      # list report
      elsif aggregation.is_list?
        
        # row headers are nils
        @header_set = Report::HeaderSet.new(@results, :col => field_set)

        # get data
        @data = @header_set.blank_data_table
        @results.each_with_index do |row, row_idx|
          row.attributes.each_pair do |col_name, value|
            r, c = @header_set.find_indices(row, row_idx, col_name)
            next if r.nil? || c.nil?
            fieldlet = @header_set.associated_fieldlet(:col, c)
            @data[r][c] = aggregation.cast_result_value(value, fieldlet)
          end
        end
        Rails.logger.debug(@data[0][0].class)
    
      # all other reports
      else
    
        # header sources depend on if there are multiple fields
        sources = field_set.multiple? ? {:row => field_set, :col => pri_grouping} : {:row => pri_grouping, :col => sec_grouping}
        @header_set = Report::HeaderSet.new(@results, sources, :default_name => aggregation.name)
      
        # get data
        @data = @header_set.blank_data_table
        @results.each_with_index do |row, row_idx|
          # get row and column indices by looking them up in the header list
          r, c = @header_set.find_indices(row, row_idx)
          
          # get associated field from row index
          fieldlet = field_set.multiple? ? @header_set.associated_fieldlet(:row, r) : field_set.only_field.fieldlets.first
          
          # set the cell value
          @data[r][c] = aggregation.cast_result_value(row["Value"], fieldlet)
        end
      end
      
      remove_blank_rows_and_columns
      remove_duplicates if unique_rows
      
    rescue Search::ParseError, Report::ReportError
      errors.add(:base, "Couldn't run report: #{$!.to_s}")
    end
  end
  
  def record_viewing
    self.viewed_at = Time.now
    self.view_count += 1
    save(:validate => false)
  end
  
  def groupings
    [pri_grouping, sec_grouping].compact
  end
  
  def to_json
    {:headers => nn(@header_set).headers,
     :header_titles => nn(@header_set).titles,
     :data => @data, 
     :totals => @totals, 
     :has_run => has_run?, 
     :id => id, 
     :name => name, 
     :aggregation => aggregation ? aggregation.name : nil,
     :grand_total => @grand_total,
     :field_choices => Report::Field.choices,
     :errors => errors.full_messages.join(", ")
    }.to_json
  end
  
  private
  
    def fields_are_legal?
      case aggregation.name
      when "Tally" then raise Report::ReportError.new("Tally reports should have no fields") unless fields.empty?
      else raise Report::ReportError.new("#{aggregation.name} reports should have at least one field") if fields.size == 0
      end
      return true
    end
    
    def must_have_fields_unless_tally
      if aggregation && !aggregation.is_tally? && fields.empty?
        errors.add(:base, "You must have at least one attribute or question")
      end
    end
    
    def remove_blank_rows_and_columns
      # loop by row
      rows_to_kill = []
      @data.each_with_index{|row, i| rows_to_kill << i if row.reject{|c| c.blank?}.empty?}
      remove_rows_by_indices(rows_to_kill)
    end
    
    def remove_duplicates
      rows_to_kill = []
      
      # generate and sort row signatures, maintaining row indices
      signatures = []
      @data.each_with_index{|row, i| signatures << {:idx => i, :sig => row.join("#&#&#")}}
      signatures.sort_by{|s| s[:sig]}
      
      # collect indices of duplicates
      signatures.inject{|prev, cur| rows_to_kill << cur[:idx] if cur[:sig] == prev[:sig]; prev = cur}
      
      # delete rows
      remove_rows_by_indices(rows_to_kill)
    end
    
    # given a sorted array of row indices, removes the rows from the data and headers safely
    def remove_rows_by_indices(indices)
      indices.reverse.each do |r|
        @data.delete_at(r)
        @header_set.delete(:row, r)
      end
    end
    
    def prep_relation
      @rel = Response.unscoped

      # add field(s)
      @rel = aggregation.is_tally? ? @rel.select("COUNT(responses.id) AS `Count`") : field_set.apply(@rel, aggregation)

      # add groupings
      groupings.each{|g| @rel = g.apply(@rel)}

      # apply filter
      @rel = filter.apply(@rel) unless filter.nil?

      # apply reviewed filter unless told not to
      @rel = @rel.where("responses.reviewed = 1") unless unreviewed?
      
      return @rel
    end
    
    def compute_totals
      if aggregation.can_total?
        @totals = @header_set.blank_total_hash
        @grand_total = 0
        @data.each_with_index do |row, r|
          row.each_with_index do |value, c|
            @totals[:row][r] += value || 0
            @totals[:col][c] += value || 0
            @grand_total += value || 0
          end
        end
      end
    end
end
