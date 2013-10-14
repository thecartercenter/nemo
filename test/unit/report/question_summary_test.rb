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
    assert_equal({}, @report.summaries[0].items)
  end

  test "integer summary should be correct with no non-blank values" do
    prepare_form_and_report('integer', [nil, ''])
    assert_equal({}, @report.summaries[0].items)
  end

  test "decimal summary should be correct in normal case" do
    prepare_form_and_report('decimal', [10.0, 7.2, 6.7, 1.1, 11.5])
    assert_equal({:mean => 7.3, :median => 7.2, :max => 11.5, :min => 1.1}, @report.summaries[0].items)
  end

  test "decimal summary should be correct with no non-blank values" do
    prepare_form_and_report('decimal', [nil, ''])
    assert_equal({}, @report.summaries[0].items)
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

  test "select_one summary should still have items if no values" do
    prepare_form_and_report('select_one', [nil, nil])
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 0, options[1] => 0}, @report.summaries[0].items)
  end

  test "select_multiple summary should be correct in normal case" do
    prepare_form_and_report('select_multiple', [%w(A), %w(B C), %w(A C)], :option_names => %w(A B C))
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 2, options[1] => 1, options[2] => 2}, @report.summaries[0].items)
  end

  test "null_count should always be zero for select_multiple" do
    prepare_form_and_report('select_multiple', [%w(A)], :option_names => %w(A B C))
    assert_equal(0, @report.summaries[0].null_count)
  end

  test "choice count should be correct for select_multiple" do
    prepare_form_and_report('select_multiple', [%w(A), %w(B C), %w(A C)], :option_names => %w(A B C))
    assert_equal(5, @report.summaries[0].choice_count)
  end

  test "date question summary should be correct in normal case" do
    prepare_form_and_report('date', %w(20131026 20131027 20131027 20131028))
    assert_equal({Date.parse('20131026') => 1, Date.parse('20131027') => 2, Date.parse('20131028') => 1}, @report.summaries[0].items)
  end

  test "date question summary keys should be sorted properly" do
    prepare_form_and_report('date', %w(20131027 20131027 20131026 20131028))
    assert_equal(%w(20131026 20131027 20131028).map{|d| Date.parse(d)}, @report.summaries[0].items.keys)
  end

  test "date question summary should work with null values" do
    prepare_form_and_report('date', ['20131027', nil])
    assert_equal({Date.parse('20131027') => 1}, @report.summaries[0].items)
  end

  test "null_count should be correct for date question summary" do
    prepare_form_and_report('date', [nil, '20131027', nil])
    assert_equal(2, @report.summaries[0].null_count)
  end

  test "time question summary should be correct in normal case" do
    prepare_form_and_report('time', %w(9:30 10:15 22:15))

    # check that the time got stored properly
    assert_equal(Time.parse('2000-01-01 9:30 UTC'), @form.responses.first.answers.first.time_value)
    
    # check stats    
    assert_equal({:mean => tp('14:00'), :median => tp('10:15'), :min => tp('9:30'), :max => tp('22:15')}, @report.summaries[0].items)
  end

  private
    def prepare_form_and_report(qtype, answers, options = {})
      prepare_form(qtype, answers, options)
      prepare_report
    end

    def prepare_form(qtype, answers, options = {})
      @form = FactoryGirl.create(:form, options.merge(:question_types => [qtype]))
      answers.each{|a| FactoryGirl.create(:response, :form => @form, :_answers => [a])}
    end

    def prepare_report
      @report = FactoryGirl.create(:standard_form_report, :form => @form)
      @report.run
    end

    def tp(s)
      Time.parse("2000-01-01 #{s} UTC")
    end
end