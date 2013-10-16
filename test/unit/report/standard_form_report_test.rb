require 'test_helper'
require 'unit/report/report_test_helper'

class Report::StandardFormReportTest < ActiveSupport::TestCase

  setup do
    @new_report = Report::StandardFormReport.new
  end

  test "should be able to init a new report" do
    assert_not_nil(@new_report)
  end

  test "form_id should default to nil" do
    assert_nil(@new_report.form_id)
  end

  test "question_order should default to number" do
    assert_equal('number', @new_report.question_order)
  end

  test "show_long_responses should default to true" do
    assert_equal(true, @new_report.show_long_responses)
  end

  test "form foreign key should work" do
    @new_report.form = FactoryGirl.create(:form)
    assert_not_nil(@new_report.form)
  end

  test "report should return correct response count" do
    build_form_and_responses
    build_and_run_report
    assert_equal(5, @report.response_count)
  end

  test "report should not contain invisible questionings" do
    build_form_and_responses
    
    # make one question invisible
    @form.questionings[1].hidden = true
    @form.save!

    build_and_run_report
    
    assert(!@report.summaries.map(&:questioning).include?(@form.questionings[1]), "summaries should not contain hidden question")
  end

  test "report should return summaries matching questions" do
    build_form_and_responses
    build_and_run_report
    assert_equal('decimal', @report.summaries[2].qtype.name)
    assert_equal(@form.questionings[0..2], @report.summaries.map(&:questioning))
  end

  test "report should skip location questions" do
    build_form_and_responses
    build_and_run_report
    assert_equal('location', @form.questionings[3].qtype_name)
    assert(!@report.summaries.map(&:questioning).include?(@form.questionings[3]), "summaries should not contain location questions")
  end

  test "report should return non-submitting observers" do
    # make observers
    observers = %w(bob jojo cass sal).map{|n| FactoryGirl.create(:user, :login => n, :role_name => :observer)}

    # make decoy coord and admin users
    coord = FactoryGirl.create(:user, :role_name => :coordinator)
    admin = FactoryGirl.create(:user, :role_name => :observer, :admin => true)

    # make simple form and add responses from first two users
    @form = FactoryGirl.create(:form)
    observers[0...2].each{|o| FactoryGirl.create(:response, :form => @form, :user => o)}

    # run report and check missing observers
    build_and_run_report
    assert_equal(%w(cass sal), @report.users_without_responses(:role => :observer).map(&:login).sort)
  end

  test "empty? should be false if responses" do
    build_form_and_responses
    build_and_run_report
    assert(!@report.empty?, "report should not be empty")
  end

  test "empty? should be true if no responses" do
    @form = FactoryGirl.create(:form)
    build_and_run_report
    assert(@report.empty?, "report should be empty")
  end

  test "report with numeric question order should have single summary group" do
    @form = FactoryGirl.create(:form)
    build_and_run_report # defaults to numeric order
    assert_equal(1, @report.groups.size)
    assert_equal(:all, @report.groups[0].type)
  end

  # test "report should cluster summaries properly" do
  #   # create two option sets
  #   @osA = FactoryGirl.create(:option_set, :option_names => %w(Yes No))
  #   @osB = FactoryGirl.create(:option_set, :option_names => %w(Red Blue Green))

  #   # create form with int dec time int sel_one(A) sel_one(A) sel_one(B) sel_mult(A) text date date date
  #   @form = FactoryGirl.create(:form)
  #   @form.questions << FactoryGirl.create(:question, )

  #   # clusters should be [int dec time int], [sel_one(A) sel_one(A)], [sel_one(B)], [sel_mult(A)], [text], [date date], [date]

  # end

  private
    def build_form_and_responses
      @form = FactoryGirl.create(:form, :question_types => %w(integer integer decimal location))
      5.times do
        FactoryGirl.create(:response, :form => @form, :_answers => [1, 2, 1.5, nil])
      end
    end

    def build_and_run_report
      @report = FactoryGirl.create(:standard_form_report, :form => @form)
      @report.run
    end
end