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


end