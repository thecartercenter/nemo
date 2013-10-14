require 'test_helper'
require 'unit/report/report_test_helper'

class Report::StandardFormReportTest < ActiveSupport::TestCase

  setup do
    @new_report = Report::StandardFormReport.new
  end

  test "should be able to init a new report" do
    assert_not_nil(@new_report)
  end

  test "form_id should default to nil" do
    assert_nil(@new_report.form_id)
  end

  test "question_order should default to number" do
    assert_equal('number', @new_report.question_order)
  end

  test "show_long_responses should default to true" do
    assert_equal(true, @new_report.show_long_responses)
  end

  test "form foreign key should work" do
    @new_report.form = FactoryGirl.create(:form)
    assert_not_nil(@new_report.form)
  end

  test "report should return correct response count" do
    build_form_and_responses
    build_and_run_report
    assert_equal(5, @report.response_count)
  end

  test "summary should contain question type" do
    build_form_and_responses
    build_and_run_report
    assert_equal('integer', @report.summaries[0].qtype.name)
  end

  test "report should not contain invisible questionings" do
    build_form_and_responses
    
    # make one question invisible
    @form.questionings[1].hidden = true
    @form.save!

    build_and_run_report
    
    assert(!@report.summaries.map(&:questioning).include?(@form.questionings[1]), "summaries should not contain hidden question")
  end

  test "integer summary should be correct" do
    build_form_and_responses
    build_and_run_report
    assert_equal({:mean => 5.0, :median => 6.0, :max => 10.0, :min => 1.0}, @report.summaries[0].items)
  end

  test "integer summary should be correct with nil values" do

  end

  test "integer summary should be correct with no values" do

  end

  private
    def build_form_and_responses
      @form = FactoryGirl.create(:form, :question_types => %w(integer integer))
      FactoryGirl.create(:response, :form => @form, :_answers => [10, 0])
      FactoryGirl.create(:response, :form => @form, :_answers => [7,  0])
      FactoryGirl.create(:response, :form => @form, :_answers => [6,  0])
      FactoryGirl.create(:response, :form => @form, :_answers => [1,  0])
      FactoryGirl.create(:response, :form => @form, :_answers => [1,  0])
    end

    def build_and_run_report
      @report = FactoryGirl.create(:standard_form_report, :form => @form)
      @report.run
    end
end