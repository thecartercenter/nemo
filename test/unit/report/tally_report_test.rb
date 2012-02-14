require 'test_helper'

class Report::TallyReportTest < ActiveSupport::TestCase

  setup do
    Language.generate
    Report::GroupingAttribute.generate
    [Question, Questioning, Answer, Place, Form].each{|k| k.delete_all}
    @qs = {}; @rs = []; @places = {}; @forms = {}; @opt_sets = {}
  end
  
  test "no groupings" do
    # create question and two responses
    create_question(:code => "num0", :type => "integer")
    create_response(:answers => {:num0 => 1})
    create_response(:answers => {:num0 => 3})
    
    # create report
    r = Report::Report.create(:kind => "Tally")
    
    assert_report(r, %w(Tally), ["Tally", "2"])
  end
  
  test "grouped by state" do
    # create places and responses
    create_places
    create_response(:place => @places["Auburn"])
    create_response(:place => @places["Atlanta"])
    create_response(:place => @places["Augusta"])

    r = Report::Report.create(:kind => "Tally")
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::GroupingAttribute.find_by_name("State"))
    
    assert_report(r, %w(Tally), %w(Alabama 1), %w(Georgia 2))
  end

  test "grouped by attrib and question with filter" do
    # create places and responses
    create_places
    create_opt_set(%w(Yes No))
    q = create_question(:code => "satisfactory", :type => "select_one")
    2.times{create_response(:place => @places["Auburn"], :answers => {:satisfactory => "Yes"})}
    create_response(:place => @places["Atlanta"], :answers => {:satisfactory => "No"})
    create_response(:place => @places["Augusta"], :answers => {:satisfactory => "Yes"})

    r = Report::Report.create(:kind => "Tally")
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::GroupingAttribute.find_by_name("State"))
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
    
    r = Report::Report.create(:kind => "Tally")
    r.pri_grouping = Report::ByAttribGrouping.create(:attrib => Report::GroupingAttribute.find_by_name("Form"))
    r.sec_grouping = Report::ByAttribGrouping.create(:attrib => Report::GroupingAttribute.find_by_name("Country"))
    
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
    
    r = Report::Report.create(:kind => "Tally")
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
    
    r = Report::Report.create(:kind => "Tally")
    r.pri_grouping = Report::ByAnswerGrouping.create(:question => q)
    r.run
    
    assert(!r.errors.empty?, "Error should be added")
  end
  
  private
    # creates a small set of localities and states
    def create_places
      PlaceType.generate
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
      QuestionType.generate
      
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
      report.data.each_with_index{|row, i| actual += [Array.wrap(report.headers[:row][i]) + row.collect{|x| x.to_s}]}
      assert_equal(expected, actual)
    end
end