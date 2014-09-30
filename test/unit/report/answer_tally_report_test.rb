# There are more report tests in spec/models/report.
require 'test_helper'
require 'unit/report/report_test_helper'

class Report::AnswerTallyReportTest < ActiveSupport::TestCase
  setup do
    prep_objects
  end

  test "counts of yes and no for all yes no questions" do
    # create several yes/no questions and responses for them
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    forms = [create_form(:name => "form0"), create_form(:name => "form1")]
    3.times{|i| create_question(:code => "yn#{i}", :name_en => "Yes No Question #{i}",
      :type => "select_one", :forms => forms, :option_set => @yes_no)}
    1.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "Yes"})}
    2.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "No"})}
    3.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "No", :yn2 => "Yes"})}
    4.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "No", :yn1 => "Yes", :yn2 => "Yes"})}
    9.times{create_response(:form => @forms[:form1], :answers => {:yn0 => "No", :yn1 => "Yes"})}

    # create report with question label 'code'
    report = create_report("AnswerTally", :option_set => @yes_no)

    # test
    assert_report(report, %w(     Yes No TTL ),
                          %w( yn0   6 13  19 ),
                          %w( yn1  16  3  19 ),
                          %w( yn2   8  2  10 ),
                          %w( TTL  30 18  48 ))


    # try question label 'title'
    report = create_report("AnswerTally", :option_set => @yes_no, :question_labels => "title")

    assert_report(report,                         %w( Yes No TTL ),
                          ["Yes No Question 0"] + %w(   6 13  19 ),
                          ["Yes No Question 1"] + %w(  16  3  19 ),
                          ["Yes No Question 2"] + %w(   8  2  10 ),
                                              %w( TTL  30 18  48 ))

    # try with joined-attrib filter
    report = create_report("AnswerTally", :option_set => @yes_no, :filter => "form: form0")
    assert_report(report, %w(     Yes No TTL ),
                          %w( yn0   6  4  10 ),
                          %w( yn1   7  3  10 ),
                          %w( yn2   8  2  10 ),
                          %w( TTL  21  9  30 ))

  end

  test "counts of options for specific questions across two option sets" do
    # create several questions and responses for them
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    @high_low = FactoryGirl.create(:option_set, :option_names => %w(High Low))
    2.times{|i| create_question(:code => "yn#{i}", :name_en => "Yes No Question #{i+1}", :type => "select_one", :option_set => @yes_no)}
    2.times{|i| create_question(:code => "hl#{i}", :name_en => "High Low Question #{i+1}", :type => "select_one", :option_set => @high_low)}
    1.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :hl0 => "High", :hl1 => "High"})}
    2.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :hl0 => "Low", :hl1 => "Low"})}
    3.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "No", :hl0 => "Low", :hl1 => "High"})}
    4.times{create_response(:answers => {:yn0 => "No", :yn1 => "Yes", :hl0 => "High", :hl1 => "Low"})}

    # create report naming only three questions
    report = create_report("AnswerTally",
      :calculations => [:yn0, :yn1, :hl1].collect{|code| Report::IdentityCalculation.new(:question1 => @questions[code])}
    )

    # test
    assert_report(report, %w(     Yes No High Low TTL ),
                          %w( yn0   6  4    _   _  10 ),
                          %w( yn1   7  3    _   _  10 ),
                          %w( hl1   _  _    4   6  10 ),
                          %w( TTL  13  7    4   6  30 ))
  end

  test "counts of yes and no for empty result" do
    # create several option sets but only responses for the last one
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    @high_low = FactoryGirl.create(:option_set, :option_names => %w(High Low))
    create_question(:code => "yn", :type => "select_one", :option_set => @yes_no)
    create_question(:code => "lh", :type => "select_one", :option_set => @high_low)
    4.times{create_response(:answers => {:lh => "Low"})}

    # create report
    report = create_report("AnswerTally", :option_set => @yes_no)

    # ensure no data
    assert_report(report, nil)
  end

  test "counts of options across a select one question and select multiple question" do
    # create several questions and responses for them
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    @rgb = FactoryGirl.create(:option_set, :option_names => %w(Red Blue Green))
    create_question(:code => "yn", :name_en => "Yes No Question", :type => "select_one", :option_set => @yes_no)
    create_question(:code => "rgb", :name_en => "Colors Question", :type => "select_multiple", :option_set => @rgb)
    1.times{create_response(:answers => {:yn => "Yes", :rgb => %w(Red Blue)})}
    2.times{create_response(:answers => {:yn => "Yes", :rgb => %w()})}
    3.times{create_response(:answers => {:yn => "Yes", :rgb => %w(Green)})}
    4.times{create_response(:answers => {:yn => "No", :rgb => %w(Red Blue Green)})}

    report = create_report("AnswerTally", :calculations => [
      Report::IdentityCalculation.new(:question1 => @questions[:yn]),
      Report::IdentityCalculation.new(:question1 => @questions[:rgb])
    ])

    # make sure we account for the null (no answer given) values that will come up for the rgb question (we use a _)
    assert_report(report, %w(      Yes No _ Red Blue Green TTL ),
                          %w( yn     6  4 _   _    _     _  10 ),
                          %w( rgb    _  _ 2   5    5     7  19 ),
                          %w( TTL    6  4 2   5    5     7  29 ))
  end
end