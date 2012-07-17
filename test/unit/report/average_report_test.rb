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
  
  test "single question field grouped by select multiple" do
    # create questions and responses
    q1 = create_question(:code => "num0", :type => "integer")
    create_opt_set(%w(Opt1 Opt2 Opt3))
    q2 = create_question(:code => "multi", :type => "select_multiple")
    create_response(:answers => {:multi => %w(Opt1 Opt2), :num0 => 1})
    create_response(:answers => {:multi => %w(Opt2), :num0 => 2})
    create_response(:answers => {:multi => %w(Opt1 Opt2 Opt3), :num0 => 4})
    
    r = create_report(:agg => "Average", :fields => [Report::Field.new(:question => q1)])
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q2)
    
    assert_report(r, %w(Average), %w(Opt1 2.5), %w(Opt2 2.3), %w(Opt3 4.0))
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