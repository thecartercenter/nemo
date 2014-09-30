# There are more report tests in spec/models/report.
require 'test_helper'
require 'unit/report/report_test_helper'

class Report::ListReportTest < ActiveSupport::TestCase
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
      {:rank => 1, :type => "Report::IdentityCalculation", :attrib1_name => "submitter"},
      {:rank => 2, :type => "Report::IdentityCalculation", :question1_id => @questions[:Inty].id},
      {:rank => 3, :type => "Report::IdentityCalculation", :question1_id => @questions[:State].id},
      {:rank => 4, :type => "Report::IdentityCalculation", :attrib1_name => "source"}
    ])

    assert_report(report, %w( Submitter  Inty  State   Source ),
                          %w( Test       10    ga      odk    ),
                          %w( Test       3     ga      web    ),
                          %w( Test       5     al      web    ))
  end

  test "list with select one" do
    @yes_no = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
    create_question(:code => "Inty", :type => "integer")
    create_question(:code => "State", :type => "text")
    create_question(:code => "Happy", :type => "select_one", :option_set => @yes_no)
    create_response(:source => "odk", :answers => {:State => "ga", :Inty => 10, :Happy => "Yes"})
    create_response(:source => "web", :answers => {:State => "ga", :Inty => 3, :Happy => "No"})
    create_response(:source => "web", :answers => {:State => "al", :Inty => 5, :Happy => "No"})

    report = create_report("List", :calculations_attributes => [
      {:rank => 1, :type => "Report::IdentityCalculation", :attrib1_name => "submitter"},
      {:rank => 2, :type => "Report::IdentityCalculation", :question1_id => @questions[:Inty].id},
      {:rank => 3, :type => "Report::IdentityCalculation", :question1_id => @questions[:State].id},
      {:rank => 4, :type => "Report::IdentityCalculation", :attrib1_name => "source"},
      {:rank => 5, :type => "Report::IdentityCalculation", :question1_id => @questions[:Happy].id}
    ])

    assert_report(report, %w( Submitter  Inty  State   Source  Happy ),
                          %w( Test       10    ga      odk     Yes   ),
                          %w( Test       3     ga      web     No    ),
                          %w( Test       5     al      web     No    ))
  end

  test "response and list reports using same attrib" do

    create_question(:code => "Inty", :type => "integer")
    create_response(:answers => {:Inty => 10})
    create_response(:answers => {:Inty => 3})

    report = create_report("List", :calculations_attributes => [
      {:rank => 1, :type => "Report::IdentityCalculation", :attrib1_name => "submitter"},
    ])

    assert_report(report, %w( Submitter ),
                          %w( Test      ),
                          %w( Test      ))

    report = create_report("ResponseTally", :calculations_attributes => [
      {:rank => 1, :type => "Report::IdentityCalculation", :attrib1_name => "submitter"}
    ])

    assert_report(report, %w(      Tally TTL ),
                          %w( Test     2   2 ),
                          %w( TTL      2   2 ))

  end
end