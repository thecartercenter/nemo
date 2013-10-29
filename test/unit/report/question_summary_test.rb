require 'test_helper'
require 'unit/report/report_test_helper'

class Report::QuestionSummaryTest < ActiveSupport::TestCase
  test "summary should contain question type" do
    prepare_form_and_report('integer', [0])
    assert_equal('integer', first_summary.qtype.name)
  end

  test "integer summary should be correct" do
    prepare_form_and_report('integer', [10, 7, 6, 1, 1])
    # assert_equal({:mean => 5.0, :median => 6.0, :max => 10, :min => 1}, headers_and_items(:stat, :stat))
    assert_equal({:mean => 5.0, :max => 10, :min => 1}, headers_and_items(:stat, :stat))
  end

  test "integer summary should not include nil or blank values" do
    prepare_form_and_report('integer', [5, nil, '', 2])
    # assert_equal({:mean => 3.5, :median => 3.5, :max => 5, :min => 2}, headers_and_items(:stat, :stat))
    assert_equal({:mean => 3.5, :max => 5, :min => 2}, headers_and_items(:stat, :stat))
  end

  test "integer summary values should be correct type" do
    prepare_form_and_report('integer', [1])
    items = first_summary.items
    assert_equal(Float, items[0].stat.class) # mean
    # assert_equal(Float, items[1].stat.class) # median
    assert_equal(Fixnum, items[1].stat.class) # max
    assert_equal(Fixnum, items[2].stat.class) # min
  end

  test "null_count should be correct for integer" do
    prepare_form_and_report('integer', [5, nil, '', 2])
    assert_equal(2, first_summary.null_count)
  end

  test "integer summary should be correct with no values" do
    prepare_form_and_report('integer', [])
    assert_equal([], first_summary.items)
  end

  test "integer summary should be correct with no non-blank values" do
    prepare_form_and_report('integer', [nil, ''])
    assert_equal([], first_summary.items)
  end

  test "decimal summary should be correct in normal case" do
    prepare_form_and_report('decimal', [10.0, 7.2, 6.7, 1.1, 11.5])
    # assert_equal({:mean => 7.3, :median => 7.2, :max => 11.5, :min => 1.1}, headers_and_items(:stat, :stat))
    assert_equal({:mean => 7.3, :max => 11.5, :min => 1.1}, headers_and_items(:stat, :stat))
  end

  test "decimal summary should be correct with no non-blank values" do
    prepare_form_and_report('decimal', [nil, ''])
    assert_equal([], first_summary.items)
  end

  test "decimal summary values should be correct type" do
    prepare_form_and_report('decimal', [1])
    items = first_summary.items
    assert_equal(Float, items[0].stat.class) # mean
    #assert_equal(Float, items[1].stat.class) # median
    assert_equal(Float, items[1].stat.class) # max
    assert_equal(Float, items[2].stat.class) # min
  end

  test "select_one summary should be correct in normal case" do
    prepare_form_and_report('select_one', %w(Yes No No No))
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 1, options[1] => 3}, headers_and_items(:option, :count))
    assert_equal({options[0] => 25.0, options[1] => 75.0}, headers_and_items(:option, :pct))
  end

  test "null_count should be correct for select_one" do
    prepare_form_and_report('select_one', ['Yes', nil, 'No', nil])
    assert_equal(2, first_summary.null_count)
  end

  test "select_one summary should still have items if no values" do
    prepare_form_and_report('select_one', [nil, nil])
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 0, options[1] => 0}, headers_and_items(:option, :count))
    assert_equal({options[0] => 0, options[1] => 0}, headers_and_items(:option, :pct))
  end

  test "select_multiple summary should be correct in normal case" do
    prepare_form_and_report('select_multiple', [%w(A), %w(B C), %w(A C), %w(C)], :option_names => %w(A B C))
    options = @form.questions[0].option_set.options
    assert_equal({options[0] => 2, options[1] => 1, options[2] => 3}, headers_and_items(:option, :count))
    assert_equal({options[0] => 50.0, options[1] => 25.0, options[2] => 75.0}, headers_and_items(:option, :pct))
  end

  test "null_count should always be zero for select_multiple" do
    prepare_form_and_report('select_multiple', [%w(A)], :option_names => %w(A B C))
    assert_equal(0, first_summary.null_count)
  end

  test "date question summary should be correct in normal case" do
    prepare_form_and_report('date', %w(20131026 20131027 20131027 20131028))
    assert_equal({Date.parse('20131026') => 1, Date.parse('20131027') => 2, Date.parse('20131028') => 1}, headers_and_items(:date, :count))
    assert_equal({Date.parse('20131026') => 25.0, Date.parse('20131027') => 50.0, Date.parse('20131028') => 25.0}, headers_and_items(:date, :pct))
  end

  test "date question summary headers should be sorted properly" do
    prepare_form_and_report('date', %w(20131027 20131027 20131026 20131028))
    assert_equal(%w(20131026 20131027 20131028).map{|d| Date.parse(d)}, first_summary.headers.map{|h| h[:date]})
  end

  test "date question summary should work with null values" do
    prepare_form_and_report('date', ['20131027', nil])
    assert_equal({Date.parse('20131027') => 1}, headers_and_items(:date, :count))
  end

  test "date question summary should work with no responses" do
    prepare_form_and_report('date', [])
    assert_equal({}, headers_and_items(:date, :count))
  end

  test "null_count should be correct for date question summary" do
    prepare_form_and_report('date', [nil, '20131027', nil])
    assert_equal(2, first_summary.null_count)
  end

  test "time question summary should be correct in normal case" do
    prepare_form_and_report('time', %w(9:30 10:15 22:15))

    # check that the time got stored properly
    assert_equal(Time.parse('2000-01-01 9:30 UTC'), @form.responses.first.answers.first.time_value)
    
    # check stats    
    # assert_equal({:mean => tp('14:00'), :median => tp('10:15'), :min => tp('9:30'), :max => tp('22:15')}, headers_and_items(:stat, :stat))
    assert_equal({:mean => tp('14:00'), :min => tp('9:30'), :max => tp('22:15')}, headers_and_items(:stat, :stat))
  end

  test "null_count should be correct for time" do
    prepare_form_and_report('time', ['9:30', nil, nil])
    assert_equal(2, first_summary.null_count)
  end

  test "time summary should be correct with no values" do
    prepare_form_and_report('time', [])
    assert_equal([], first_summary.items)
  end

  test "datetime summary should be correct in normal case" do
    prepare_form_and_report('datetime', ['2013-10-26 18:45', '2013-10-26 10:15', '2013-10-27 19:00'])

    # check stats
    # assert_equal({:mean => dtp('2013-10-27 00:00'), :median => dtp('2013-10-26 18:45'), 
    #   :min => dtp('2013-10-26 10:15'), :max => dtp('2013-10-27 19:00')}, 
    #   headers_and_items(:stat, :stat))
    assert_equal({:mean => dtp('2013-10-27 00:00'),
      :min => dtp('2013-10-26 10:15'), :max => dtp('2013-10-27 19:00')}, 
      headers_and_items(:stat, :stat))
  end

  test "null_count should be correct for datetime" do
    prepare_form_and_report('datetime', ['2013-10-26 9:30', nil, nil])
    assert_equal(2, first_summary.null_count)
  end

  test "text summary should be correct in normal case" do
    prepare_form_and_report('text', ['foo', 'bar'])
    assert_equal(['foo', 'bar'], first_summary.items.map(&:text))
  end

  test "null_count should work for text summary" do
    prepare_form_and_report('text', ['foo', nil, 'bar', ''])
    assert_equal(2, first_summary.null_count)
  end

  test "text summary should work with no values" do
    prepare_form_and_report('text', [])
    assert_equal([], first_summary.items)
    assert_equal(0, first_summary.null_count)
  end

  test "long_text summary should include response_id" do
    prepare_form_and_report('long_text', ['foo', 'bar'])
    assert_equal(@form.responses.map(&:id), first_summary.items.map(&:response_id))
  end

  test "text summary items should be in chronological order" do
    prepare_form('text', ['foo', 'bar', 'baz'])

    # change response dates
    @form.responses[1].answers[0].created_at += 1.hour
    @form.responses[1].answers[0].save!
    @form.responses[2].answers[0].created_at -= 1.day
    @form.responses[2].answers[0].save!
    @form.reload

    prepare_report

    # check for correct order
    assert_equal(%w(baz foo bar), first_summary.items.map(&:text))
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

    # parse a time value
    def tp(s)
      I18n.l(Time.parse("2000-01-01 #{s} UTC"), :format => :time_only)
    end

    # parse a datetime value
    def dtp(s)
      I18n.l(Time.zone.parse(s))
    end

    # gets the first summary in the generated report
    def first_summary
      @report.subreports[0].summaries[0]
    end

    # generates a hash of headers to items for testing purposes
    def headers_and_items(header_attrib, item_attrib)
      Hash[*first_summary.headers.each_with_index.map{|h, i| [h[header_attrib], first_summary.items[i].send(item_attrib)]}.flatten(1)]
    end
end