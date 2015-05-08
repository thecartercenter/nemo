# There are more report tests in spec/models/report.
require 'spec_helper'
require 'unit/report/report_test_helper'

describe Report::Report do

  before do
  end

  it "reports must have missions" do
    assert_raise(ActiveRecord::RecordInvalid) do
      create(:report, :mission => nil)
    end
  end
end