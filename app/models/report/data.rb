# models the data table that results from the report
class Report::Data

  attr_accessor :rows
  attr_accessor :total_row_count
  attr_accessor :returned_row_count
  attr_accessor :truncated
  attr_reader :totals

  def initialize(rows)
    @rows = rows
    @truncated = false
  end

  # sets the value of the cell given by row, col to value
  # if options[:append] is true and the cell already has a value, the new value is appended. otherwise it overwrites.
  # also handles translations
  def set_cell(row, col, value, options = {})
    # make sure row and col indices are set
    return if row.nil? || col.nil?

    value = Report::Formatter.translate(value)

    if !@rows[row][col].blank? && options[:append]
      @rows[row][col] = "#{@rows[row][col]}, #{value}"
    else
      @rows[row][col] = value
    end
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

  # Strips any extra rows. This is also done at the query level, but a few extra are left on
  # so we can tell if we are actually truncating or not and set a flag to display to the user.
  def truncate(max_rows)
    if @rows.size > max_rows
      @truncated = true
      @rows.slice!(max_rows..-1)
      true
    else
      false
    end
  end

  def as_json(options = {})
    {rows: @rows, totals: @totals, total_row_count: @total_row_count, returned_row_count: @returned_row_count}
  end
end
