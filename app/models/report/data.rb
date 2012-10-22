# models the data table that results from the report
class Report::Data
  
  attr_reader :totals
  
  def initialize(arr)
    @arr = arr
  end
  
  def set_cell(row, col, value)
    @arr[row][col] = value unless row.nil? || col.nil?
  end
  
  def empty?
    @arr.empty?
  end
  
  def rows
    @arr
  end
  
  def compute_totals
    # get first row size carefully to avoid nil
    first_row_size = @arr.first ? @arr.first.size : 0
    
    # make blank totals hash
    @totals = {:row => Array.new(@arr.size, 0), :col => Array.new(first_row_size, 0), :grand => 0}
    
    # compute
    @arr.each_with_index do |row, r|
      row.each_with_index do |value, c|
        safe_value = value || 0
        @totals[:row][r] += safe_value
        @totals[:col][c] += safe_value
        @totals[:grand] += safe_value
      end
    end
  end
end