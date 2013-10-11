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
end