# frozen_string_literal: true

require "rspec/expectations"

RSpec::Matchers.define(:end_with) do |expected|
  match do |actual|
    actual[-expected.size..-1] == expected
  end
end

RSpec::Matchers.define(:be_destroyed) do
  match do |actual|
    raise "expected nil to not be destroyed" if actual.nil?
    !actual.class.exists?(actual.id)
  end
end

# Compares gridable report with expected data given as array of arrays representing grid.
RSpec::Matchers.define(:have_data_grid) do |*expected|
  match do |report|
    raise "Report errors: " + report.errors.full_messages.join(", ") unless report.errors.empty?

    # if nil is expected, compute the right expected value
    expected = report.data.totals ? [["TTL"], %w[TTL 0]] : [] if expected.first.nil?

    # Convert _ to ' '
    expected.each do |row|
      row.map! { |c| c.is_a?(String) ? c.gsub(/_(?=.)/, " ") : c }
    end

    expected == to_grid(report)
  end

  failure_message do |report|
    "Expected #{to_grid(report)} to equal #{expected}"
  end

  def to_grid(report)
    # Add header row.
    actual = [report.header_set[:col].collect(&:name)]
    actual[0] << "TTL" if report.data.totals

    # Add main rows.
    report.data.rows.each_with_index { |row, i| actual << actual_row(report, row, i) }

    # Add column total row.
    actual += [["TTL"] + report.data.totals[:col] + [report.data.totals[:grand]]] if report.data.totals

    # Convert everything to string; convert empty strings to "_".
    actual.map { |row| row.map { |cell| cell.to_s.empty? ? "_" : cell.to_s } }
  end

  def actual_row(report, row, row_idx)
    result = []

    # Add col header.
    if report.header_set[:row] && report.header_set[:row].cells[row_idx]
      result << report.header_set[:row].cells[row_idx].name
    end

    result += row

    # Add row total.
    result << report.data.totals[:row][row_idx] if report.data.totals

    result
  end
end

RSpec::Matchers.define(:match_user_facing_csv) do |expected|
  match do |actual|
    doc = "\xEF\xBB\xBF" + expected
    doc.to_s == actual
  end
end

RSpec::Matchers.define(:have_errors) do |errors|
  match do |object|
    object.invalid? && errors.all? do |field, pattern|
      object.errors[field].join.match?(pattern)
    end
  end
  failure_message do |object|
    if object.valid?
      "expected object to be invalid but it was valid"
    else
      failing = errors.detect { |f, p| !object.errors[f].join.match?(p) }
      "expected errors on #{failing[0]} to match #{failing[1].inspect} "\
        "but was #{object.errors[failing[0]].inspect}"
    end
  end
end
