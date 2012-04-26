require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::ListReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end
  
  test "one attrib only" do
    create_response(:source => "web")
    create_response(:source => "odk")
    create_response(:source => "odk")
    
    r = create_report(:agg => "List",
      :fields => [Report::Field.new(:attrib => Report::ResponseAttribute.find_by_name("Source"))])
    
    assert_report(r, %w(Source), %w(web), %w(odk), %w(odk))
  end

  test "one attrib and one question" do
    q = create_question(:code => "num0", :type => "decimal")
    r = create_response(:source => "web", :answers => {:num0 => "1.1"})
    create_response(:source => "odk", :answers => {:num0 => "4.7"})
    create_response(:source => "odk", :answers => {:num0 => "5.2"})
    
    r = create_report(:agg => "List",
      :fields => [Report::Field.new(:attrib => Report::ResponseAttribute.find_by_name("Source")),
        Report::Field.new(:question => q)])
    
    assert_report(r, %w(Source num0), %w(web 1.1), %w(odk 4.7), %w(odk 5.2))
  end

end