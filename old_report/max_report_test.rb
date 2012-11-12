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
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    # number should not have decimal since the question is integer type
    assert_report(r, %w(Maximum), ["Maximum", "4"])
  end

  test "date question field with no groupings" do
    set_eastern_timezone
    # create question and two responses
    q = create_question(:code => "date0", :type => "date")
    create_response(:answers => {:date0 => "2010-03-29"})
    create_response(:answers => {:date0 => "2010-04-01"})
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Maximum), ["Maximum", "2010-04-01"])
  end

  test "time question field with no groupings" do
    set_eastern_timezone
    # create question and two responses
    q = create_question(:code => "time0", :type => "time")
    create_response(:answers => {:time0 => "2:03:14"})
    create_response(:answers => {:time0 => "12:44:56"})
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Maximum), ["Maximum", "12:44"])
  end
  
  test "datetime question field with no groupings" do
    set_eastern_timezone
    # create question and two responses
    q = create_question(:code => "datetime0", :type => "datetime")
    create_response(:answers => {:datetime0 => "2010-08-12 02:03:14"})
    create_response(:answers => {:datetime0 => "2011-01-14 01:44:56"})
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Maximum), ["Maximum", "2011-01-14 01:44"])
  end

  test "datetime question field with DST and no groupings" do
    set_eastern_timezone
    # create question and two responses
    q = create_question(:code => "datetime0", :type => "datetime")
    create_response(:answers => {:datetime0 => "2010-08-12 02:03:14"})
    create_response(:answers => {:datetime0 => "2011-06-14 01:44:56"})
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Maximum), ["Maximum", "2011-06-14 01:44"])
  end

  test "decimal question field with no groupings" do
    # create question and two responses
    q = create_question(:code => "num0", :type => "decimal")
    create_response(:answers => {:num0 => 1.1})
    create_response(:answers => {:num0 => 4.7})
    
    # create report and set to maximum
    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Maximum), ["Maximum", "4.7"])
  end
  
  test "date attrib field with no groupings" do
    set_eastern_timezone
    
    # create question and two responses
    create_response(:created_at => Time.zone.parse("2012-01-01 12:00:00"))
    create_response(:created_at => Time.zone.parse("2012-01-01 13:30:00"))
    
    # create report and set to average
    r = create_report(:agg => "Maximum",
     :fields => [Report::Field.new(:attrib => Report::ResponseAttribute.find_by_name("Time Submitted"))])
    
    # date should be in string format in the correct timezone
    assert_report(r, %w(Maximum), ["Maximum", "2012-01-01 13:30"])
  end
end