require 'test_helper'
require 'unit/report/report_test_helper'

class Report::QuestionSummaryTest < ActiveSupport::TestCase

  test "summary should contain question type" do
    prepare_form_and_report('integer', [0])
    assert_equal('integer', @report.summaries[0].qtype.name)
  end

  test "integer summary should be correct" do
    prepare_form_and_report('integer', [10, 7, 6, 1, 1])
    assert_equal({:mean => 5.0, :median => 6.0, :max => 10.0, :min => 1.0}, @report.summaries[0].items)
  end

  test "integer summary should not include nil or blank values" do
    prepare_form_and_report('integer', [5, nil, '', 2])
    assert_equal({:mean => 3.5, :median => 3.5, :max => 5.0, :min => 2.0}, @report.summaries[0].items)
  end

  test "integer summary should be correct with no values" do
    prepare_form_and_report('integer', [])
    assert(@report.summaries[0].empty?, 'summary should say it\'s empty')
    assert_nil(@report.summaries[0].items)
  end

  test "integer summary should be correct with no non-blank values" do

  end
  
  private
    def prepare_form_and_report(qtype, answers)
      @form = FactoryGirl.create(:form, :question_types => [qtype])
      answers.each{|a| FactoryGirl.create(:response, :form => @form, :_answers => [a])}
      @report = FactoryGirl.create(:standard_form_report, :form => @form)
      @report.run
    end
end