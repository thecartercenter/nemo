require 'test_helper'
require 'unit/report/report_test_helper'

class Report::QuestionSummaryTest < ActiveSupport::TestCase

  test "summary should contain question type" do
    build_form_and_responses
    build_and_run_report
    assert_equal('integer', @report.summaries[0].qtype.name)
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