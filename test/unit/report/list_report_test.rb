require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::ListReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end

  test "basic list" do
    
    create_question(:code => "Inty", :type => "integer")
    create_question(:code => "State", :type => "text")
    create_response(:source => "odk", :answers => {:State => "ga", :Inty => 10})
    create_response(:source => "web", :answers => {:State => "ga", :Inty => 3})
    create_response(:source => "web", :answers => {:State => "al", :Inty => 5})
    
    report = create_report("List", :calculations_attributes => [
      {:rank => 1, :type => "Report::IdentityCalculation", :question1_id => @questions[:Inty].id},
      {:rank => 2, :type => "Report::IdentityCalculation", :question1_id => @questions[:State].id},
      {:rank => 3, :type => "Report::IdentityCalculation", :attrib1_name => "source"}
    ])        
    
    assert_report(report, %w( Inty  State   Source ),
                          %w( 10    ga      odk    ),
                          %w( 3     ga      web    ),
                          %w( 5     al      web    ))
  end
end