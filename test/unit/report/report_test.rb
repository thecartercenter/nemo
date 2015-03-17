# There are more report tests in spec/models/report.
require 'test_helper'
require 'unit/report/report_test_helper'

class Report::ReportTest < ActiveSupport::TestCase

  setup do
  end

  test "reports must have missions" do
    assert_raise(ActiveRecord::RecordInvalid) do
      FactoryGirl.create(:report, :mission => nil)
    end
  end
end