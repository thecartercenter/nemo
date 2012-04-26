require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::AverageReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end
  
  test "question field with no groupings" do
    # create question and two responses
    q = create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 4})
    
    # create report and set to average
    r = create_report(:agg => "Average", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Average), ["Average", "2.5"])
  end
  
  test "question field with blanks" do
    # create question and two responses
    q = create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 2})
    create_response(:answers => {:num0 => " "})
    create_response(:answers => {:num0 => ""})
    create_response(:answers => {:num0 => nil})
    
    # create report and set to average
    r = create_report(:agg => "Average", :fields => [Report::Field.new(:question => q)])
    
    assert_report(r, %w(Average), ["Average", "1.5"])
  end
  
  test "single question field grouped by state" do
    # create places, question and responses
    create_places
    q = create_question(:code => "num0", :type => "integer")
    
    # alabama
    create_response(:place => @places["Auburn"], :answers => {:num0 => 1})
    create_response(:place => @places["Auburn"], :answers => {:num0 => 4})
    # georgia
    create_response(:place => @places["Atlanta"], :answers => {:num0 => 7})
    create_response(:place => @places["Augusta"], :answers => {:num0 => 8})

    r = create_report(:agg => "Average", :fields => [Report::Field.new(:question => q)])
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("State"))
    
    assert_report(r, %w(Average), %w(Alabama 2.5), %w(Georgia 7.5))
  end
  
  test "single question field grouped by state and source" do
    # create places, question and responses
    create_places
    q = create_question(:code => "num0", :type => "integer")
    
    # alabama
    create_response(:place => @places["Auburn"], :source => "odk", :answers => {:num0 => 2})
    create_response(:place => @places["Auburn"], :source => "odk", :answers => {:num0 => 4})
    create_response(:place => @places["Auburn"], :source => "odk", :answers => {:num0 => 3})
    create_response(:place => @places["Auburn"], :source => "web", :answers => {:num0 => 5})
    # georgia
    create_response(:place => @places["Atlanta"], :source => "odk", :answers => {:num0 => 7})
    create_response(:place => @places["Augusta"], :source => "odk", :answers => {:num0 => 8})
    create_response(:place => @places["Atlanta"], :source => "web", :answers => {:num0 => 9})
    create_response(:place => @places["Augusta"], :source => "web", :answers => {:num0 => 11})

    r = create_report(:agg => "Average", :fields => [Report::Field.new(:question => q)])
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("State"))
    r.sec_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Source"))
    
    assert_report(r, %w(odk web), %w(Alabama 3.0 5.0), %w(Georgia 7.5 10.0))
  end
  

  test "multiple question fields with no groupings" do
    # create two questions and two responses
    q1 = create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 4})
    q2 = create_question(:code => "num1", :type => "integer")
    r1 = create_response(:answers => {:num1 => 2})
    create_response(:answers => {:num1 => 5})
    
    # create report, set to average, and add fields
    r = create_report(:agg => "Average", 
      :fields => [Report::Field.new(:question => q1), Report::Field.new(:question => q2)])
    
    assert_report(r, %w(Average), %w(num0 2.5), %w(num1 3.5))
  end

  test "question_type field with no groupings" do 
    # create three questions
    int0 = create_question(:code => "int0", :type => "integer")
    int1 = create_question(:code => "int1", :type => "integer")
    dec = create_question(:code => "dec", :type => "decimal")
    
    # create some responses
    create_response(:answers => {:int0 => 1})
    create_response(:answers => {:int0 => 2})
    create_response(:answers => {:int1 => 3})
    create_response(:answers => {:int1 => 4})
    create_response(:answers => {:dec => 500.234})
    
    r = create_report(:agg => "Average",
     :fields => [Report::Field.new(:question_type => QuestionType.find_by_name("integer"))])
    
    assert_report(r, %w(Average), %w(int0 1.5), %w(int1 3.5))
  end

  test "question_type field grouped by source" do 
    # create three questions
    int0 = create_question(:code => "int0", :type => "integer")
    int1 = create_question(:code => "int1", :type => "integer")
    dec = create_question(:code => "dec", :type => "decimal")
    
    # create some responses
    create_response(:source => "odk", :answers => {:int0 => 1})
    create_response(:source => "odk", :answers => {:int0 => 2})
    create_response(:source => "odk", :answers => {:int1 => 3})
    create_response(:source => "odk", :answers => {:int1 => 4})
    create_response(:source => "web", :answers => {:int0 => 5})
    create_response(:source => "web", :answers => {:int0 => 6})
    create_response(:source => "web", :answers => {:int1 => 7})
    create_response(:source => "web", :answers => {:int1 => 8})
    create_response(:source => "odk", :answers => {:dec => 500.234})

    r = create_report(:agg => "Average",
     :fields => [Report::Field.new(:question_type => QuestionType.find_by_name("integer"))])
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Source"))
    
    assert_report(r, %w(odk web), %w(int0 1.5 5.5), %w(int1 3.5 7.5))
  end

  
  test "no matches" do 
    create_question(:code => "int0", :type => "integer")
    r = create_report(:agg => "Average",
     :fields => [Report::Field.new(:question_type => QuestionType.find_by_name("integer"))])
    assert_report(r, nil)
  end
end