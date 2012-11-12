require 'test/test_helper'
require 'test/unit/report/report_test_helper'
class Report::SingleFieldAggregatedReportTest < ActiveSupport::TestCase
  include ReportTestHelper

  setup do
    prep_objects
  end

  test "max and avg answer for an integer question per state" do
    forms = [create_form(:name => "form0"), create_form(:name => "form1")]
    create_question(:code => "int", :type => "integer", :forms => forms)
    create_question(:code => "state", :type => "text", :forms => forms)
    create_response(:form => @forms[:form0], :answers => {:state => "ga", :int => 10})
    create_response(:form => @forms[:form0], :answers => {:state => "ga", :int => 3})
    create_response(:form => @forms[:form0], :answers => {:state => "al", :int => 5})
    create_response(:form => @forms[:form0], :answers => {:state => "al", :int => 12})
    create_response(:form => @forms[:form1], :answers => {:state => "ga", :int => 499})
    
    report = create_report("SingleFieldAggregated", :aggregation_name => "maximum", 
      :calculation => Report::IdentityCalculation.new(:question1 => @questions[:int]),
      :pri_group_by => Report::IdentityCalculation.new(:question1 => @questions[:state]))
    assert_report(report, %w(      _ ),
                          %w( al  12 ),
                          %w( ga 499 ))
                          
    # try with filter
    report.update_attributes(:filter_attributes => {:str => "form: form0", :class_name => "Response"})
    assert_report(report, %w(     _ ),
                          %w( al 12 ),
                          %w( ga 10 ))
                          
    # try average
    report = create_report("SingleFieldAggregated", :aggregation_name => "average", 
      :calculation => Report::IdentityCalculation.new(:question1 => @questions[:int]),
      :pri_group_by => Report::IdentityCalculation.new(:question1 => @questions[:state]))
    assert_report(report, %w(            _ ),
                          %w( al    8.50 ),
                          %w( ga  170.67 ))
    
  end
  
  test "max answer for a text question per state and source" do
    create_opt_set(%w(Yes No))
    create_question(:code => "txt", :type => "text")
    create_question(:code => "state", :type => "text")
    create_question(:code => "yn", :type => "select_one")
    create_response(:source => "odk", :answers => {:state => "ga", :yn => "Yes", :txt => "Apple"})
    create_response(:source => "odk", :answers => {:state => "ga", :yn => "Yes", :txt => "Banana"})
    create_response(:source => "odk", :answers => {:state => "al", :yn => "Yes", :txt => "Zulu"})
    create_response(:source => "odk", :answers => {:state => "al", :yn => "Yes", :txt => "Charlie"})
    create_response(:source => "web", :answers => {:state => "ga", :yn => "No", :txt => "Papa"})
    create_response(:source => "web", :answers => {:state => "ga", :yn => "No", :txt => "Oscar"})
    create_response(:source => "web", :answers => {:state => "al", :yn => "No", :txt => "Delta"})
    create_response(:source => "web", :answers => {:state => "al", :yn => "No", :txt => "Xray"})
  
    report = create_report("SingleFieldAggregated", :aggregation_name => "maximum", 
      :calculation => Report::IdentityCalculation.new(:question1 => @questions[:txt]),
      :pri_group_by => Report::IdentityCalculation.new(:question1 => @questions[:state]),
      :sec_group_by => Report::IdentityCalculation.new(:attrib1_name => "source"))
    assert_report(report, %w(    odk     web ),
                          %w( al Zulu    Xray),
                          %w( ga Banana  Papa))
                          
    # try grouping by other question
    report = create_report("SingleFieldAggregated", :aggregation_name => "maximum", 
      :calculation => Report::IdentityCalculation.new(:question1 => @questions[:txt]),
      :pri_group_by => Report::IdentityCalculation.new(:question1 => @questions[:state]),
      :sec_group_by => Report::IdentityCalculation.new(:question1 => @questions[:yn]))
    assert_report(report, %w(    Yes     No ),
                          %w( al Zulu    Xray),
                          %w( ga Banana  Papa))
  end
  
end