require 'test_helper'
require 'unit/report/report_test_helper'

class Report::GroupedTallyReportTest < ActiveSupport::TestCase
  setup do
    prep_objects
  end

  test "counts of yes, no per day for a given question" do
    # create several yes/no questions and responses for them
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    create_question(:code => "yn", :type => "select_one", :option_set => @yes_no)
    1.times{create_response(:created_at => Time.zone.parse("2012-01-01 1:00:00"), :answers => {:yn => "Yes"})}
    2.times{create_response(:created_at => Time.zone.parse("2012-01-05 1:00:00"), :answers => {:yn => "Yes"})}
    6.times{create_response(:created_at => Time.zone.parse("2012-01-05 1:00:00"), :answers => {:yn => "No"})}

    # create report with question label 'code'
    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :attrib1_name => :date_submitted),
      Report::IdentityCalculation.new(:rank => 2, :question1 => @questions[:yn])
    ])

    # test
    assert_report(report, %w(            Yes No TTL ),
                          ["Jan 01 2012"] + %w( 1  _   1 ),
                          ["Jan 05 2012"] + %w( 2  6   8 ),
                          %w( TTL               3  6   9 ))
  end

  test "total number of responses per form per source" do
    create_form(:name => "f0")
    create_form(:name => "f1")
    2.times{create_response(:form => @forms[:f0], :source => "odk")}
    5.times{create_response(:form => @forms[:f0], :source => "web")}
    8.times{create_response(:form => @forms[:f1], :source => "odk")}
    3.times{create_response(:form => @forms[:f1], :source => "web")}

    report = create_report("GroupedTally", :calculations => [Report::IdentityCalculation.new(:rank => 1, :attrib1_name => :form)])
    assert_report(report, %w(   Tally TTL ),
                          %w(  f0  7   7 ),
                          %w(  f1 11  11 ),
                          %w( TTL 18  18 ))

    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :attrib1_name => :form),
      Report::IdentityCalculation.new(:rank => 2, :attrib1_name => :source)
    ])

    assert_report(report, %w(     odk web TTL ),
                          %w(  f0   2   5   7 ),
                          %w(  f1   8   3  11 ),
                          %w( TTL  10   8  18 ))
  end

  test "total number of responses per source per answer" do
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    create_question(:code => "yn", :type => "select_one", :option_set => @yes_no)
    2.times{create_response(:source => "odk", :answers => {:yn => "Yes"})}
    5.times{create_response(:source => "web", :answers => {:yn => "Yes"})}
    8.times{create_response(:source => "odk", :answers => {:yn => "No"})}
    3.times{create_response(:source => "web", :answers => {:yn => "No"})}

    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :attrib1_name => :source),
      Report::IdentityCalculation.new(:rank => 2, :question1 => @questions[:yn])
    ])
    assert_report(report, %w(     Yes  No TTL ),
                          %w( odk   2   8  10 ),
                          %w( web   5   3   8 ),
                          %w( TTL   7  11  18 ))
  end

  test "total number of responses per source per zero-nonzero answer" do
    create_question(:code => "int", :type => "integer")
    2.times{create_response(:source => "odk", :answers => {:int => 4})}
    5.times{create_response(:source => "web", :answers => {:int => 9})}
    8.times{create_response(:source => "odk", :answers => {:int => 0})}
    3.times{create_response(:source => "web", :answers => {:int => 0})}

    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :attrib1_name => :source),
      Report::ZeroNonzeroCalculation.new(:rank => 2, :question1 => @questions[:int])
    ])

    assert_report(report, %w(     Zero) + ["One or More"] + %w(TTL ),
                          %w( odk    8                2         10 ),
                          %w( web    3                5          8 ),
                          %w( TTL   11                7         18 ))
  end

  test "total number of responses per two different answers" do
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    @high_low = FactoryGirl.create(:option_set, :option_names => %w(High Low))
    forms = [create_form(:name => "form0"), create_form(:name => "form1")]
    create_question(:code => "yn", :type => "select_one", :option_set => @yes_no, :forms => forms)
    create_question(:code => "hl", :type => "select_one", :option_set => @high_low, :forms => forms)
    2.times{create_response(:form => @forms[:form0], :answers => {:yn => "Yes", :hl => "High"})}
    5.times{create_response(:form => @forms[:form0], :answers => {:yn => "No", :hl => "High"})}
    8.times{create_response(:form => @forms[:form0], :answers => {:yn => "Yes", :hl => "Low"})}
    3.times{create_response(:form => @forms[:form0], :answers => {:yn => "No", :hl => "Low"})}
    2.times{create_response(:form => @forms[:form1], :answers => {:yn => "Yes", :hl => "High"})}

    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :question1 => @questions[:yn]),
      Report::IdentityCalculation.new(:rank => 2, :question1 => @questions[:hl])
    ])
    assert_report(report, %w(    High Low TTL ),
                          %w( Yes   4   8  12 ),
                          %w( No    5   3   8 ),
                          %w( TTL   9  11  20 ))

    report = create_report("GroupedTally", :calculations => [
      Report::IdentityCalculation.new(:rank => 1, :question1 => @questions[:yn]),
      Report::IdentityCalculation.new(:rank => 2, :question1 => @questions[:hl])
    ], :filter_attributes => {:str => "form: form0", :class_name => "Response"})

    assert_report(report, %w(    High Low TTL ),
                          %w( Yes   2   8  10 ),
                          %w( No    5   3   8 ),
                          %w( TTL   7  11  18 ))

  end

end
