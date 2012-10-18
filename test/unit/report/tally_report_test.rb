require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::TallyReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end
    
  test "no groupings" do
    # create question and two responses
    create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 3})
    
    # create report
    r = create_report(:agg => "Tally")
    
    assert_report(r, %w(Tally), ["Tally", "2"])
  end
  
  test "grouped by date" do
    set_eastern_timezone
    # create responses so that the day of some of them will change across timezones
    2.times{create_response(:created_at => Time.parse("2012-01-02 2:00:00 UTC"))}
    create_response(:created_at => Time.parse("2012-01-02 6:00:00 UTC"))

    r = create_report(:agg => "Tally")
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Date Submitted"))
    
    # results should be split across two days
    assert_report(r, %w(Tally), %w(2012-01-01 2), %w(2012-01-02 1))
  end

  test "grouped by two questions" do
    create_opt_set(%w(Yes No))
    q1 = create_question(:code => "satisfactory", :type => "select_one")
    q2 = create_question(:code => "openontime", :type => "select_one")
    1.times{create_response(:answers => {:satisfactory => "Yes", :openontime => "Yes"})}
    5.times{create_response(:answers => {:satisfactory => "Yes", :openontime => "No"})}
    3.times{create_response(:answers => {:satisfactory => "No", :openontime => "Yes"})}
    2.times{create_response(:answers => {:satisfactory => "No", :openontime => "No"})}
    
    r = create_report(:agg => "Tally")
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q1)
    r.sec_grouping = Report::ByAnswerGrouping.create(:question => q2)
    
    assert_report(r, %w(    Yes No), 
                     %w(Yes 1  5  ), 
                     %w(No  3  2  ))
  end 
  
  test "group by question with no questionings" do
    create_opt_set(%w(Yes No))
    q = create_question(:code => "satisfactory", :type => "select_one")
    q.questionings.destroy_all
    
    r = create_report(:agg => "Tally")
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q)
    r.run
    
    assert(!r.errors.empty?, "Error should be added")
  end
  
  
  test "group by select multiple question" do
    create_opt_set(%w(Opt1 Opt2 Opt3))
    q = create_question(:code => "multi", :type => "select_multiple")
    create_response(:answers => {:multi => %w(Opt1 Opt2)})
    create_response(:answers => {:multi => %w(Opt2)})
    create_response(:answers => {:multi => %w(Opt1 Opt2 Opt3)})
    create_response(:answers => {:multi => []})
    
    r = create_report(:agg => "Tally")
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q)
    
    assert_report(r, %w(Tally), %w(Opt1 2), %w(Opt2 3), %w(Opt3 1))
  end

  test "group by source and select multiple question" do
    create_opt_set(%w(Opt1 Opt2 Opt3))
    q = create_question(:code => "multi", :type => "select_multiple")
    create_response(:answers => {:multi => %w(Opt1 Opt2)}, :source => "web")
    create_response(:answers => {:multi => %w(Opt2)}, :source => "web")
    create_response(:answers => {:multi => %w(Opt1 Opt2 Opt3)}, :source => "odk")
    create_response(:answers => {:multi => []}, :source => "odk")
    
    r = create_report(:agg => "Tally")
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q)
    r.sec_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Source"))
    
    assert_report(r, %w(    odk web), 
                     %w(Opt1  1   1), 
                     %w(Opt2  1   2),
                     %w(Opt3  1   ) + [""])
  end
  
  test "group by question and answer with form and option_set filter" do
    yes_no = create_opt_set(%w(Yes No))
    good_bad = create_opt_set(%w(Good Bad))

    form1 = create_form(:name => "Form 1")
    q1 = create_question(:code => "satisfactory", :type => "select_one", :forms => [form1])
    q2 = create_question(:code => "openontime", :type => "select_one", :forms => [form1])
    q3 = create_question(:code => "hotdogs", :type => "integer", :forms => [form1])
    1.times{create_response(:form => form1, :answers => {:satisfactory => "Yes", :openontime => "Yes", :hotdogs => "2"})}
    5.times{create_response(:form => form1, :answers => {:satisfactory => "Yes", :openontime => "No", :hotdogs => "2"})}
    3.times{create_response(:form => form1, :answers => {:satisfactory => "No", :openontime => "Yes", :hotdogs => "2"})}
    2.times{create_response(:form => form1, :answers => {:satisfactory => "No", :openontime => "No", :hotdogs => "2"})}

    form2 = create_form(:name => "Form 2")
    q4 = create_question(:code => "awesome", :type => "select_one")
    3.times{create_response(:form => form2, :answers => {:awesome => "Yes"})}
    2.times{create_response(:form => form2, :answers => {:awesome => "No"})}

    form3 = create_form(:name => "Form 3")
    q4 = create_question(:code => "happy", :type => "select_one")
    3.times{create_response(:form => form3, :answers => {:happy => "Yes"})}
    2.times{create_response(:form => form3, :answers => {:happy => "No"})}

    r = create_report(:agg => "Tally")
    r.filter = Search::Search.new(:class_name => "Response", :str => "option-set:YesNo formname:\"Form 1\", \"Form 2\"")
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Question Title"))
    r.sec_grouping = Report::ByAttribGrouping.create(:attrib => Report::ResponseAttribute.find_by_name("Answer (Option Name)"))
    
    assert_report(r, %w(             Yes No ), 
                     %w(awesome        3  2 ), 
                     %w(openontime     4  7 ),
                     %w(satisfactory   6  5 )) 
  end
  

end