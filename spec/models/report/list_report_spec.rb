require 'spec_helper'

describe Report::ListReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
      @response = create(:response, form: @form, answer_values: [['Animal', 'Cat']])
      @report = create(:list_report, _calculations: [@form.questions[0]])
    end

    it 'should have answer values in correct order' do
      assert_report(@report, ["Question Title 1"], ["Animal, Cat"])
    end
  end

  def assert_report(report, *expected)
    # reload the report so we know it's saving properly
    report.reload

    # run it
    report.run

    # check for report errors
    raise "Report errors: " + report.errors.full_messages.join(", ") unless report.errors.empty?

    # get the actual
    actual = get_actual(report)

    # if nil is expected, compute the right expected value
    if expected.first.nil?
      expected = report.data.totals ? [["TTL"], ["TTL", "0"]] : []
    end

    # sort and compare
    assert_equal(expected, actual)
  end

  def assert_report_empty(report)
    assert_report(report, *expected)
  end

  def get_actual(report)
    # get the first row of the 'actual' table
    actual = [report.header_set[:col].collect{|cell| cell.name}]

    # add the row total column if applicable
    actual[0] << "TTL" if report.data.totals

    # get the rest of the 'actual' table
    report.data.rows.each_with_index do |row, i|
      actual_row = []

      if report.header_set[:row] && report.header_set[:row].cells[i]
        actual_row << report.header_set[:row].cells[i].name
      end

      actual_row += row

      # add the row total if applicable
      actual_row << report.data.totals[:row][i] if report.data.totals

      # add to row to the matrix
      actual += [actual_row]
    end

    # add the column total row if applicable
    actual += [["TTL"] + report.data.totals[:col] + [report.data.totals[:grand]]] if report.data.totals

    # convert everything to string, except convert "" to "_"
    actual.collect{|row| row.collect{|cell| cell.to_s == "" ? "_" : cell.to_s}}
  end
end
