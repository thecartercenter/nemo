require 'rspec/expectations'

RSpec::Matchers.define :end_with do |expected|
  match do |actual|
    actual[-expected.size..-1] == expected
  end
end

RSpec::Matchers.define :be_destroyed do
  match do |actual|
    raise 'expected nil to not be destroyed' if actual.nil?
    !actual.class.exists?(actual.id)
  end
end

# Compares gridable report with expected data given as array of arrays representing grid.
RSpec::Matchers.define :have_data_grid do |*expected|
  match do |report|
    raise "Report errors: " + report.errors.full_messages.join(", ") unless report.errors.empty?

    # if nil is expected, compute the right expected value
    expected = report.data.totals ? [["TTL"], ["TTL", "0"]] : [] if expected.first.nil?

    # Convert _ to ' '
    expected.each do |row|
      row.map!{ |c| c.is_a?(String) ? c.gsub(/_(?=.)/, " ") : c }
    end

    expected == to_grid(report)
  end

  failure_message do |report|
    "Expected #{to_grid(report)} to equal #{expected}"
  end

  def to_grid(report)
    # Add header row.
    actual = [report.header_set[:col].collect{|cell| cell.name}]
    actual[0] << "TTL" if report.data.totals

    report.data.rows.each_with_index do |row, i|
      actual_row = []

      # Add col header.
      if report.header_set[:row] && report.header_set[:row].cells[i]
        actual_row << report.header_set[:row].cells[i].name
      end

      actual_row += row

      # Add row total.
      actual_row << report.data.totals[:row][i] if report.data.totals

      actual << actual_row
    end

    # Add column total row.
    actual += [["TTL"] + report.data.totals[:col] + [report.data.totals[:grand]]] if report.data.totals

    # Convert everything to string; convert empty strings to "_".
    actual.map{|row| row.map{|cell| cell.to_s.empty? ? "_" : cell.to_s}}
  end
end

RSpec::Matchers.define :match_csv do |expected|
  match do |actual|
    # Strip BOM from actual
    doc = actual.gsub("\xEF\xBB\xBF", "")
    doc.to_s == expected
  end
end
