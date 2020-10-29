# frozen_string_literal: true

# Models the data table that results from the report.
class Report::Data
  attr_accessor :rows, :truncated
  attr_reader :totals

  # Initialize the data grid with the given number of rows and cols.
  # The grid will auto-expand as needed.
  def initialize(rows:, cols:)
    @cols = cols
    ensure_rows(rows)
    @truncated = false
  end

  # Sets the value of the cell given by row, col to value
  # if options[:append] is true and the cell already has a value,
  # the new value is appended. otherwise it overwrites.
  # Also handles translations.
  def set_cell(row, col, value, options = {})
    # make sure row and col indices are set
    return if row.nil? || col.nil?

    ensure_rows(row + 1)
    value = Report::Formatter.translate(value)

    @rows[row][col] =
      if @rows[row][col].present? && options[:append]
        "#{@rows[row][col]}, #{value}"
      else
        value
      end
  end

  def empty?
    @rows.empty?
  end

  def empty_row?(i)
    @rows[i].all?(&:blank?)
  end

  def compute_totals
    # get first row size carefully to avoid nil
    first_row_size = @rows.first ? @rows.first.size : 0

    # make blank totals hash
    @totals = {row: Array.new(@rows.size, 0), col: Array.new(first_row_size, 0), grand: 0}

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

  def as_json(_options = {})
    {rows: rows, totals: totals, truncated: truncated}
  end

  # Ensures there are at least num rows in the table. If not, adds new rows consisting of all nils.
  def ensure_rows(num)
    @rows ||= []
    deficit = num - @rows.size
    return unless deficit.positive?
    deficit.times { @rows << Array.new(@cols) }
  end
end
