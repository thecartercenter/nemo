require 'test_helper'

class Report::ResponseCountReportTest < ActiveSupport::TestCase

  setup do
    [Question, Questioning, Answer, Place, Form].each{|k| k.delete_all}
    @qs = {}; @rs = []; @places = {}; @forms = {}; @opt_sets = {}
  end
  
  test "no groupings" do
    # create question and two responses
    create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 3})
    
    # create report
    r = Report::ResponseCountReport.create
    
    assert_report(r, [], %w(2))
  end
  
  test "grouped by state" do
    # create places and responses
    create_places
    create_response(:place => @places["Auburn"])
    create_response(:place => @places["Atlanta"])
    create_response(:place => @places["Augusta"])

    r = Report::ResponseCountReport.create
    r.pri_grouping = Report::ByAttribGrouping.find_by_name("State")
    
    assert_report(r, %w(Count), %w(Alabama 1), %w(Georgia 2))
  end

  test "grouped by attrib and question with filter" do
    # create places and responses
    create_places
    create_opt_set(%w(Yes No))
    q = create_question(:code => "satisfactory", :type => "select_one")
    2.times{create_response(:place => @places["Auburn"], :answers => {:satisfactory => "Yes"})}
    create_response(:place => @places["Atlanta"], :answers => {:satisfactory => "No"})
    create_response(:place => @places["Augusta"], :answers => {:satisfactory => "Yes"})

    r = Report::ResponseCountReport.create
    r.pri_grouping = Report::ByAttribGrouping.find_by_name("State")
    r.sec_grouping = Report::ByAnswerGrouping.create(:question => q)
    r.filter = Search::Search.create(:class_name => "Response", :str => "place != Atlanta")
    
    assert_report(r, %w(Yes), %w(Alabama 2), %w(Georgia 1))
  end
  
  test "grouped by two attributes" do
    create_places
    create_form(:name => "f0")
    create_form(:name => "f1")
    1.times{create_response(:place => @places["Canada"], :form => @forms[:f0])}
    5.times{create_response(:place => @places["Canada"], :form => @forms[:f1])}
    3.times{create_response(:place => @places["USA"], :form => @forms[:f0])}
    2.times{create_response(:place => @places["USA"], :form => @forms[:f1])}
    
    r = Report::ResponseCountReport.create
    r.pri_grouping = Report::ByAttribGrouping.find_by_name("Form")
    r.sec_grouping = Report::ByAttribGrouping.find_by_name("Country")
    
    assert_report(r, %w(Canada USA), %w(f0 1 3), %w(f1 5 2))
  end
  
  test "grouped by two questions" do
    create_places
    create_opt_set(%w(Yes No))
    q1 = create_question(:code => "satisfactory", :type => "select_one")
    q2 = create_question(:code => "openontime", :type => "select_one")
    1.times{create_response(:answers => {:satisfactory => "Yes", :openontime => "Yes"})}
    5.times{create_response(:answers => {:satisfactory => "Yes", :openontime => "No"})}
    3.times{create_response(:answers => {:satisfactory => "No", :openontime => "Yes"})}
    2.times{create_response(:answers => {:satisfactory => "No", :openontime => "No"})}
    
    r = Report::ResponseCountReport.create
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q1)
    r.sec_grouping = Report::ByAnswerGrouping.create(:question => q2)
    
    assert_report(r, %w(    No Yes), 
                     %w(No  2  3  ), 
                     %w(Yes 5  1  ))
  end 
  
  test "group by question with no questionings" do
    create_opt_set(%w(Yes No))
    q = create_question(:code => "satisfactory", :type => "select_one")
    q.questionings.destroy_all
    
    r = Report::ResponseCountReport.create
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q)
    
    assert_raise(Report::ReportError){r.run}
  end
  
#  test "no aggregation" do
#    # create question and two responses
#    t1 = Time.now; t2 = Time.now - 1.minute
#    create_question(:code => "num", :type => "integer")
#    create_response(:observed_at => t1, :answers => {:num => 2})
#    create_response(:observed_at => t2, :answers => {:num => 5})
#    
#    # reload responses so Times compare properly
#    @rs.each{|resp| resp.reload}
#    
#    # create report
#    r = Report::Report.create
#    r.fields.create(:report => r, :attrib_name => "observed_at")
#    r.fields.create(:report => r, :question => @qs[:num])
#    r.run
#    
#    assert_report(r, %w(observed_at num), [@rs[0].observed_at, "2"], [@rs[1].observed_at, "5"])
#  end
#  
#  test "average of numerical question with no questionings" do
#    # create question with no questionings
#    create_question(:code => "num", :type => "integer")
#    @qs[:num].questionings.delete_all
#    
#    # create report
#    r = Report::Report.create(:aggregation => Report::Aggregation.find_by_name("Average"))
#    r.fields.create(:question => @qs[:num])
#    
#    assert_raise(Report::ReportError){r.run}
#  end  
#  
#  test "average of numerical question" do
#    # create question and responses
#    create_question(:code => "num", :type => "integer")
#    create_response(:answers => {:num => 1})
#    create_response(:answers => {:num => 4})
#    
#    # create report
#    r = Report::Report.create(:aggregation => Report::Aggregation.find_by_name("Average"))
#    f = r.fields.create(:question => @qs[:num])
#    
#    # assert
#    assert_report(r, [], %w(num 2.5))
#  end
#  
#  test "average with nulls grouped by country, form" do
#    # create places and responses
#    create_places
#    create_form(:name => "f0")
#    create_form(:name => "f1")
#    create_question(:code => "num", :forms => [@forms[:f0], @forms[:f1]], :type => "decimal")
#    create_response(:place => @places["Canada"], :form => @forms[:f0], :answers => {:num => 1.5})
#    create_response(:place => @places["Canada"], :form => @forms[:f0], :answers => {:num => 2})
#    create_response(:place => @places["Canada"], :form => @forms[:f1], :answers => {:num => 3.5})
#    create_response(:place => @places["Canada"], :form => @forms[:f1], :answers => {:num => 4})
#    create_response(:place => @places["USA"], :form => @forms[:f0], :answers => {:num => 5.5})
#    create_response(:place => @places["USA"], :form => @forms[:f0], :answers => {:num => 6})
#    create_response(:place => @places["USA"], :form => @forms[:f0], :answers => {:num => nil})
#    create_response(:place => @places["USA"], :form => @forms[:f1], :answers => {:num => 7.5})
#    create_response(:place => @places["USA"], :form => @forms[:f1], :answers => {:num => 8})
#    create_response(:place => @places["USA"], :form => @forms[:f1], :answers => {:num => 11.5})
#
#    # create report with field as average num, grouped by country, form
#    r = Report::Report.create(:aggregation => Report::Aggregation.find_by_name("Average"))
#    r.fields.create(:question => @qs[:num])
#    r.pri_grouping = Report::Grouping.find_by_name("Form")
#    r.sec_grouping = Report::Grouping.find_by_name("Country")
#    
#    assert_report(r, %w(Canada USA), %w(f0 1.75 5.75), %w(f1 3.75 9))
#  end
#  
#  test "answer counts per option per all select_one questions" do
#    # select questions.code, options.name, count(answers.id) 
#    # from answers join questionings join questions join question_types join options join translations
#    # where question_types.id = X
#    # group by questions.code, options.name
#    create_opt_set(%w(Yes No))
#    create_question(:code => "sel1", :type => "select_one")
#    4.times{create_response(:answers => {:sel1 => "Yes"})}
#    2.times{create_response(:answers => {:sel1 => "No"})}
#    create_question(:code => "sel2", :type => "select_one")
#    5.times{create_response(:answers => {:sel1 => "Yes"})}
#    6.times{create_response(:answers => {:sel1 => "No"})}
#    
#    r = Report::Report.create(:aggregation => Report::Aggregation.find_by_name("Answer Count"))
#    r.fields.create(:question_type => QuestionType.find_by_name("select_one"))
#    r.pri_grouping = Report::Grouping.find_by_name("Questions")
#    r.sec_grouping = Report::Grouping.find_by_name("Answers")
#    
#    assert_report(r, %w(Yes No), %w(sel1 4 2), %w(sel2 5 6))
#  end
#
#  test "averages of all numerical questions" do
#    # create two integer questions and responses
#    create_question(:code => "num0", :type => "integer")
#    create_question(:code => "num1", :type => "integer")
#    create_response(:answers => {:num0 => 1, :num1 => 9})
#    create_response(:answers => {:num0 => 4, :num1 => 12})
#
#    # create report
#    r = Report::Report.create(:aggregation => Report::Aggregation.find_by_name("Average"))
#    f = r.fields.create(:question_type => QuestionType.find_by_name("integer"))
#    r.pri_grouping = Report::Grouping.find_by_name("Questions")
#    
#    # assert
#    assert_report(r, [], %w(num1 10.5), %w(num0 2.5))
#  end
  
  private
    # creates a small set of localities and states
    def create_places
      create_place(:type => :country, :name => "Canada")
      create_place(:type => :country, :name => "USA")
      create_place(:type => :state, :name => "Alabama", :container => "USA")
      create_place(:type => :locality, :name => "Auburn", :container => "Alabama")
      create_place(:type => :locality, :name => "Montgomery", :container => "Alabama")
      create_place(:type => :state, :name => "Georgia", :container => "USA")
      create_place(:type => :locality, :name => "Atlanta", :container => "Georgia")
      create_place(:type => :locality, :name => "Augusta", :container => "Georgia")
    end
    
    def create_opt_set(options)
      os = OptionSet.new(:name => options.join, :ordering => "value_asc")
      options.each_with_index{|o,i| os.option_settings.build(:option => Option.new(:value => i+1, :name_eng => o))}
      os.save!
      @opt_sets[options.join("_").downcase.to_sym] = os
    end
    
    def create_place(params)
      params[:place_type] = PlaceType.find_by_short_name(params.delete(:type))
      params[:long_name] = params.delete(:name)
      params[:container] = @places[params[:container]]
      p = Place.create!(params)
      @places[params[:long_name]] = p
    end
    
    def create_form(params)
      f = Form.new(params)
      f.save(:validate => false)
      @forms[params[:name].to_sym] = f
    end
  
    def create_question(params)
      q = Question.new(:code => params[:code], :question_type_id => QuestionType.find_by_name(params[:type]).id)
      
      # set the option set if type is select_one
      q.option_set = params[:option_set] || @opt_sets.first[1] if params[:type] == "select_one"
      
      # create default form if necessary
      params[:forms] ||= [create_form(:name => "f")]
      
      # create questionings for each form
      params[:forms].each{|f| q.questionings.build(:form => f)}
      
      # save and store in hash
      q.save(:validate => false)
      @qs[params[:code].to_sym] = q
    end
    
    def create_response(params)
      ans = params.delete(:answers) || {}
      r = Response.new(params)
      ans.each_pair do |code,value|
        qing = @qs[code].questionings.first
        case qing.question.type.name
        when "select_one"
          r.answers.build(:questioning_id => qing.id, :option => qing.question.options.find{|o| o.name_eng == value})
        else
          r.answers.build(:questioning_id => qing.id, :value => value)
        end
      end
      r.save(:validate => false)
      @rs << r
    end
    
    def assert_report(report, *expected)
      report.run
      raise "Missing headers" if report.headers.nil? || report.headers[:col].nil? || report.headers[:row].nil?
      raise "Bad data array" if report.data.nil? || report.data.empty?
      actual = [report.headers[:col]]
      report.data.each_with_index{|row, i| actual += [Array.wrap(report.headers[:row][i]) + row]}
      assert_equal(expected, actual)
    end
end