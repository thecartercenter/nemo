require 'test_helper'

class Report::QuestionAnswerTallyReportTest < ActiveSupport::TestCase
  setup do
    prep_objects
  end

  test "counts of yes and no for all yes-no questions" do
    # create several yes/no questions and responses for them
    create_opt_set(%w(Yes No))
    forms = [create_form(:name => "form0"), create_form(:name => "form1")]
    3.times{|i| create_question(:code => "yn#{i}", :name_eng => "Yes No Question #{i}", :type => "select_one", :forms => forms)}
    1.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "Yes"})}
    2.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "Yes", :yn2 => "No"})}
    3.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "Yes", :yn1 => "No", :yn2 => "Yes"})}
    4.times{create_response(:form => @forms[:form0], :answers => {:yn0 => "No", :yn1 => "Yes", :yn2 => "Yes"})}
    9.times{create_response(:form => @forms[:form1], :answers => {:yn0 => "No", :yn1 => "Yes"})}
    
    # create report with question label 'code'
    report = create_report("QuestionAnswerTally", :option_set => @option_sets[:yes_no])
    
    # test                   
    assert_report(report, %w(     Yes No TTL ),
                          %w( yn0   6 13  19 ),
                          %w( yn1  16  3  19 ),
                          %w( yn2   8  2  10 ),
                          %w( TTL  30 18  48 ))

                          
    # try question label 'title'
    report = create_report("QuestionAnswerTally", :option_set => @option_sets[:yes_no], :question_labels => "Title")

    assert_report(report,                         %w( Yes No TTL ),
                          ["Yes No Question 0"] + %w(   6 13  19 ),
                          ["Yes No Question 1"] + %w(  16  3  19 ),
                          ["Yes No Question 2"] + %w(   8  2  10 ),
                                              %w( TTL  30 18  48 ))
    
    # try with joined-attrib filter
    report = create_report("QuestionAnswerTally", :option_set => @option_sets[:yes_no],
      :filter_attributes => {:str => "form: form0", :class_name => "Response"})
    assert_report(report, %w(     Yes No TTL ),
                          %w( yn0   6  4  10 ),
                          %w( yn1   7  3  10 ),
                          %w( yn2   8  2  10 ),
                          %w( TTL  21  9  30 ))

  end
  
  test "Counts of Yes and No for specific questions" do
    # create several questions and responses for them
    create_opt_set(%w(Yes No))
    create_opt_set(%w(High Low))
    2.times{|i| create_question(:code => "yn#{i}", :name_eng => "Yes No Question #{i+1}", :type => "select_one", :option_set => @option_sets[:yes_no])}
    2.times{|i| create_question(:code => "hl#{i}", :name_eng => "High Low Question #{i+1}", :type => "select_one", :option_set => @option_sets[:high_low])}
    1.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :hl0 => "High", :hl1 => "High"})}
    2.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :hl0 => "Low", :hl1 => "Low"})}
    3.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "No", :hl0 => "Low", :hl1 => "High"})}
    4.times{create_response(:answers => {:yn0 => "No", :yn1 => "Yes", :hl0 => "High", :hl1 => "Low"})}
    
    # create report naming only three questions
    report = create_report("QuestionAnswerTally", 
      :calculations => [:yn0, :yn1, :hl1].collect{|code| Report::IdentityCalculation.new(:question1 => @questions[code])}
    )
    
    
    # test                   
    assert_report(report, %w(     High Low Yes No TTL ),
                          %w( hl1    4   6   _  _  10 ),
                          %w( yn0    _   _   6  4  10 ),
                          %w( yn1    _   _   7  3  10 ),
                          %w( TTL    4   6  13  7  30 ))
  end
  
  test "counts of yes and no for empty result" do
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

  test "counts of yes and no and zero/nonzero" do
    # create several questions and responses for them
    create_opt_set(%w(Yes No))
    2.times{|i| create_question(:code => "yn#{i}", :name_eng => "Yes No Question #{i+1}", :type => "select_one", :option_set => @option_sets[:yes_no])}
    create_question(:code => "int", :type => "integer")
    create_question(:code => "dec", :type => "decimal")
    1.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :int => 3, :dec => 1.5})}
    2.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "Yes", :int => 2, :dec => 0})}
    3.times{create_response(:answers => {:yn0 => "Yes", :yn1 => "No", :int => 0, :dec => 4.5})}
    4.times{create_response(:answers => {:yn0 => "No", :yn1 => "Yes", :int => 0, :dec => 0})}

    # create report naming only three questions
    report = create_report("QuestionAnswerTally", :calculations => [
      Report::IdentityCalculation.new(:question1 => @questions[:yn0]),
      Report::ZeroNonzeroCalculation.new(:question1 => @questions[:int]),
      Report::ZeroNonzeroCalculation.new(:question1 => @questions[:dec])
    ])
    
    # test                   
    assert_report(report, %w(     Zero) + ["One or More"] + %w(Yes No TTL ),
                          %w( dec    6                4          _  _  10 ),
                          %w( int    7                3          _  _  10 ),
                          %w( yn0    _                _          6  4  10 ),
                          %w( TTL   13                7          6  4  30 ))
   end
   
  # try it with multiselect
  # try it with filter
end