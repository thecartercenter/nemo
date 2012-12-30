# models the data table that results from the report
class Report::Data
  
  attr_accessor :rows
  attr_reader :totals
  
  def initialize(rows)
    @rows = rows
  end
  
  def set_cell(row, col, value)
    @rows[row][col] = value unless row.nil? || col.nil?
  end
  
  def empty?
    @rows.empty?
  end
  
  def empty_row?(i)
    @rows[i].detect{|c| !c.blank?}.nil?
  end
  
  def compute_totals
    # get first row size carefully to avoid nil
    first_row_size = @rows.first ? @rows.first.size : 0
    
    # make blank totals hash
    @totals = {:row => Array.new(@rows.size, 0), :col => Array.new(first_row_size, 0), :grand => 0}
    
    # compute
    @rows.each_with_index do |row, r|
      row.each_with_index do |value, c|
        safe_value = value || 0
        @totals[:row][r] += safe_value
        @totals[:col][c] += safe_value
        @totals[:grand] += safe_value
      end
    end
  end
  
  def as_json(options = {})
    {:rows => @rows, :totals => @totals}
  end 
end