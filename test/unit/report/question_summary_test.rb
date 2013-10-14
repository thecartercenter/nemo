require 'test_helper'
require 'unit/report/report_test_helper'

class Report::QuestionSummaryTest < ActiveSupport::TestCase

  test "summary should contain question type" do
    prepare_form_and_report('integer', [0])
    assert_equal('integer', @report.summaries[0].qtype.name)
  end

  test "integer summary should be correct" do
    prepare_form_and_report('integer', [10, 7, 6, 1, 1])
    assert_equal({:mean => 5.0, :median => 6.0, :max => 10, :min => 1}, @report.summaries[0].items)
  end

  test "integer summary should not include nil or blank values" do
    prepare_form_and_report('integer', [5, nil, '', 2])
    assert_equal({:mean => 3.5, :median => 3.5, :max => 5, :min => 2}, @report.summaries[0].items)
  end

  test "integer summary values should be correct type" do
    prepare_form_and_report('integer', [1])
    items = @report.summaries[0].items
    assert_equal(Fixnum, items[:max].class)
    assert_equal(Fixnum, items[:min].class)
    assert_equal(Float, items[:mean].class)
    assert_equal(Float, items[:median].class)
  end

  test "null_count should be correct for integer" do
    prepare_form_and_report('integer', [5, nil, '', 2])
    assert_equal(2, @report.summaries[0].null_count)
  end

  test "integer summary should be correct with no values" do
    prepare_form_and_report('integer', [])
    assert(@report.summaries[0].empty?, 'summary should say it\'s empty')
    assert_equal({}, @report.summaries[0].items)
  end

  test "integer summary should be correct with no non-blank values" do
    prepare_form_and_report('integer', [nil, ''])
    assert(@report.summaries[0].empty?, 'summary should say it\'s empty')
  end

  test "decimal summary should be correct in normal case" do
    prepare_form_and_report('decimal', [10.0, 7.2, 6.7, 1.1, 11.5])
    assert_equal({:mean => 7.3, :median => 7.2, :max => 11.5, :min => 1.1}, @report.summaries[0].items)
  end

  test "decimal summary should be correct with no non-blank values" do
    prepare_form_and_report('decimal', [nil, ''])
    assert(@report.summaries[0].empty?, 'summary should say it\'s empty')
  end

  test "decimal summary values should be correct type" do
    prepare_form_and_report('decimal', [1])
    items = @report.summaries[0].items
    assert_equal(Float, items[:max].class)
    assert_equal(Float, items[:min].class)
    assert_equal(Float, items[:mean].class)
    assert_equal(Float, items[:median].class)
  end

  test "select_one summary should be correct in normal case" do
    prepare_form_and_report('select_one', %w(Yes No No No))
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 1, options[1] => 3}, @report.summaries[0].items)
  end

  test "null_count should be correct for select_one" do
    prepare_form_and_report('select_one', ['Yes', nil, 'No', nil])
    assert_equal(2, @report.summaries[0].null_count)
  end

  test "select_one summary should be correct if no values" do
  end

  private
    def prepare_form_and_report(qtype, answers)
      prepare_form(qtype, answers)
      prepare_report
    end

    def prepare_form(qtype, answers)
      @form = FactoryGirl.create(:form, :question_types => [qtype])
      answers.each{|a| FactoryGirl.create(:response, :form => @form, :_answers => [a])}
    end

    def prepare_report
      @report = FactoryGirl.create(:standard_form_report, :form => @form)
      @report.run
    end
end