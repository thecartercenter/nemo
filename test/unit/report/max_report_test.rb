require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::MaxReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end
  
  test "integer question field with no groupings" do
    # create question and two responses
    q = create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 4})
    
    # create report and set to average
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    # number should not have decimal since the question is integer type
    assert_report(r, %w(Maximum), ["Maximum", "4"])
  end

  test "decimal question field with no groupings" do
    # create question and two responses
    q = create_question(:code => "num0", :type => "decimal")
    create_response(:answers => {:num0 => 1.1})
    create_response(:answers => {:num0 => 4.7})
    
    # create report and set to average
    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:question => q)])
    
    # number should not have decimal since the question is integer type
    assert_report(r, %w(Maximum), ["Maximum", "4.7"])
  end
  
  test "date attrib field with no groupings" do
    set_eastern_timezone
    
    # create question and two responses
    create_response(:observed_at => Time.parse("2012-01-01 17:00:00 UTC"))
    create_response(:observed_at => Time.parse("2012-01-01 18:30:00 UTC"))
    
    # create report and set to average
    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:attrib => Report::ResponseAttribute.find_by_name("Time Observed"))])
    
    # date should be in string format in the correct timezone
    assert_report(r, %w(Maximum), ["Maximum", "2012-01-01 13:30:00"])
  end
  
  test "state attrib field with no groupings" do
    # create two responses
    create_places
    create_response(:place => @places["Auburn"])
    create_response(:place => @places["Augusta"])
    
    # create report and set to average
    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:attrib => Report::ResponseAttribute.find_by_name("State"))])
    
    # date should be in string format in the correct timezone
    assert_report(r, %w(Maximum), ["Maximum", "Georgia"])
  end
  
  test "integer question field grouped by state" do
    # create places, question and responses
    create_places
    q = create_question(:code => "num0", :type => "integer")
    
    # alabama
    create_response(:place => @places["Auburn"], :answers => {:num0 => 1})
    create_response(:place => @places["Auburn"], :answers => {:num0 => 4})
    # georgia
    create_response(:place => @places["Atlanta"], :answers => {:num0 => 7})
    create_response(:place => @places["Augusta"], :answers => {:num0 => 8})

    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:question => q)])
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("State"))
    
    assert_report(r, %w(Maximum), %w(Alabama 4), %w(Georgia 8))
  end
end