require 'test/test_helper'
require 'test/unit/report/report_test_helper'

class Report::QuestionAnswerTallyReportTest < ActiveSupport::TestCase
  include ReportTestHelper
  
  setup do
    prep_objects
  end

  test "Counts of Yes and No for all Yes-No questions" do
    # create several yes/no questions and responses for them
    create_opt_set(%w(Yes No))
    3.times{|i| create_question(:code => "yn#{i}", :name_eng => "Yes No Question #{i+1}", :type => "select_one")}
    1.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "Yes"})}
    2.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "No"})}
    3.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "No", :yn2 => "Yes"})}
    4.times{create_response(:answers => {:yn0 => "No", :yn1 => "Yes", :yn2 => "Yes"})}
    
    # create report with question label 'code'
    report = create_report("QuestionAnswerTally", :option_set => @option_sets[:yes_no], :question_labels => :codes)
    
    # test                   
    assert_report(report, %w(     Yes No TTL ),
                          %w( yn0   6  4  10 ),
                          %w( yn1   7  3  10 ),
                          %w( yn2   8  2  10 ),
                          %w( TTL  21  9  30 ))
  end
  
  test "Counts of Yes and No for empty result" do
    # create several option sets but only responses for the last one
    create_opt_set(%w(Yes No))
    create_opt_set(%w(Low High))
    create_question(:code => "yn", :type => "select_one", :option_set => @option_sets[:yes_no])
    create_question(:code => "lh", :type => "select_one", :option_set => @option_sets[:low_high])
    4.times{create_response(:answers => {:lh => "Low"})}
    
    # create report
    report = create_report("QuestionAnswerTally", :option_set => @option_sets[:yes_no])
    
    # ensure no data
    assert_report(report, nil)
  end
      
  # try it with specific questions instead of option set
  # try it with filter
  # try it with the zero/nonzero calculation
end