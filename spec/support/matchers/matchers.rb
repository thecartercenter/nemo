# frozen_string_literal: true

require "rspec/expectations"

# Generates a diff failure message with adjusted actual and/or expected values instead of the ones
# passed to the matcher.
def diff_with_adjusted_actual_expected(actual, expected)
  message = <<~TEXT.strip
    expected: #{expected.inspect}
    got: #{actual.inspect}
  TEXT

  diff = RSpec::Expectations.differ.diff(actual, expected)

  unless diff.strip.empty?
    diff_label = RSpec::Matchers::ExpectedsForMultipleDiffs::DEFAULT_DIFF_LABEL
    message << "\n\n" << diff_label << diff
  end
  message
end

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

  diffable
end

RSpec::Matchers.define(:have_attached_file) do |name|
  match do |record|
    file = record.send(name)
    file.respond_to?(:variant) && file.respond_to?(:attach)
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

# Taken from https://github.com/winebarrel/rspec-match_fuzzy/blob/master/lib/rspec/match_fuzzy.rb
# Matches strings without caring about whitespace between words.
RSpec::Matchers.define(:match_words) do |expected|
  expected = expected.to_s

  match do |actual|
    actual.to_s.strip.gsub(/[[:blank:]]+/, "").gsub(/\n+/, "") == expected.strip.gsub(/[[:blank:]]+/, "")
      .gsub(/\n+/, "")
  end

  failure_message do |actual|
    actual = actual.to_s.strip.gsub(/^\s+/, "").gsub(/[[:blank:]]+/, "\s").gsub(/\n+/, "").gsub(/\s+$/, "")
    expected = expected.strip.gsub(/^\s+/, "").gsub(/[[:blank:]]+/, "\s").gsub(/\n+/, "").gsub(/\s+$/, "")
    diff_with_adjusted_actual_expected(actual, expected)
  end
end

RSpec::Matchers.define(:match_json) do |expected|
  match do |actual|
    JSON.pretty_generate(actual).strip == expected.strip
  end

  failure_message do |actual|
    diff_with_adjusted_actual_expected(JSON.pretty_generate(actual).strip, expected.strip)
  end
end
