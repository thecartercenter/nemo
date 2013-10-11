require 'test_helper'
require 'unit/report/report_test_helper'

class Report::StandardFormReportTest < ActiveSupport::TestCase

  test "should be able to init a new report" do
    @r = Report::StandardFormReport.new
    assert_not_nil(@r)
  end

end