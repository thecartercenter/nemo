ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  
  #####################################################
  # REPORT TEST HELPERS
  
  def prep_objects
    Role.generate
    
    # clear out tables
    [Question, Questioning, Answer, Form, User, Mission].each{|k| k.delete_all}
    
    # create hashes to store generated objs
    @questions, @forms, @option_sets, @users, @missions = {}, {}, {}, {}, {}
  end
  
  def create_report(klass, options)
    
    # handle option_set parameter
    if option_set = options.delete(:option_set)
      options[:option_set_choices_attributes] = [{:option_set_id => option_set.id}]
    end
    
    report = "Report::#{klass}Report".constantize.new_with_default_name(mission)
    report.update_attributes!({:name => "TheReport"}.merge(options))
    return report
  end

  def create_opt_set(options)
    os = OptionSet.new(:name => options.join, :ordering => "value_asc", :mission => mission)
    options.each_with_index{|o,i| os.option_settings.build(:option => Option.new(:value => i+1, :name_eng => o))}
    os.save!
    @option_sets[options.join("_").downcase.to_sym] = os
  end

  def create_form(params)
    f = Form.new(params.merge(:mission => mission))
    f.save(:validate => false)
    @forms[params[:name].to_sym] = f
  end
  
  def mission
    @missions[:test] ||= Mission.create!(:name => "test")
  end
  
  def user
    return @users[:test] if @users[:test]
    @users[:test] = User.new_with_login_and_password(:login => "test", :name => "Test", :reset_password_method => "print")
    @users[:test].assignments.build(:mission => mission, :active => true, :role => Role.highest)
    @users[:test].save!
    @users[:test]
  end

  def create_question(params)
    QuestionType.generate
    
    # create default form if necessary
    params[:forms] ||= [create_form(:name => "f")]  
    
    q = Question.new(:name_eng => params[:name_eng] || params[:code], :code => params[:code], :mission => mission,
      :question_type_id => QuestionType.find_by_name(params[:type]).id)
  
    # set the option set if type is select_one or select_multiple
    q.option_set = params[:option_set] || @option_sets.first[1] if %w(select_one select_multiple).include?(params[:type])
  
    # save and store in hash
    q.save!
    @questions[params[:code].to_sym] = q
    
    # create questionings for each form
    params[:forms].each{|f| q.questionings.create(:form => f)}
  end

  def create_response(params)
    ans = params.delete(:answers) || {}
    params[:form] ||= @forms[:f] || create_form(:name => "f")
    r = Response.new({:reviewed => true, :user => user, :mission => mission}.merge(params))
    ans.each_pair do |code,value|
      qing = @questions[code].questionings.first
      case qing.question.type.name
      when "select_one"
        # create answer with option_id
        r.answers.build(:questioning_id => qing.id, :option => qing.question.options.find{|o| o.name_eng == value})
      when "select_multiple"
        # create answer with several choices
        a = r.answers.build(:questioning_id => qing.id)
        value.each{|opt| a.choices.build(:option => qing.question.options.find{|o| o.name_eng == opt})}
      when "datetime", "date", "time"
        a = r.answers.build(:questioning_id => qing.id, :"#{qing.question.type.name}_value" => value)
      else
        r.answers.build(:questioning_id => qing.id, :value => value)
      end
    end
    r.save!
    
    # set created_at if needed
    r.update_attributes(:created_at => params[:created_at]) if params[:created_at]
    
    r
  end

  def set_eastern_timezone
    Time.zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
  end

  def assert_report(report, *expected)
    # reload the report so we know it's saving properly
    report.reload
    
    # run it
    report.run

    # check for report errors
    raise "Report errors: " + report.errors.full_messages.join(", ") unless report.errors.empty?

    # get the actual
    actual = get_actual(report)

    # if nil is expected, compute the right expected value
    if expected.first.nil?
      expected = report.data.totals ? [["TTL"], ["TTL", "0"]] : []
    end

    # sort and compare
    assert_equal(expected, actual)
  end
  
  def assert_report_empty(report)
    assert_report(report, *expected)
  end
  
  def get_actual(report)
    # get the first row of the 'actual' table
    actual = [report.header_set[:col].collect{|cell| cell.name}]
    
    # add the row total column if applicable
    actual[0] << "TTL" if report.data.totals
    
    # get the rest of the 'actual' table
    report.data.rows.each_with_index do |row, i|
      actual_row = []

      if report.header_set[:row] && report.header_set[:row].cells[i]
        actual_row << report.header_set[:row].cells[i].name
      end
      
      actual_row += row
      
      # add the row total if applicable
      actual_row << report.data.totals[:row][i] if report.data.totals
      
      # add to row to the matrix
      actual += [actual_row]
    end

    # add the column total row if applicable
    actual += [["TTL"] + report.data.totals[:col] + [report.data.totals[:grand]]] if report.data.totals
    
    # convert everything to string, except convert "" to "_"
    actual.collect{|row| row.collect{|cell| cell.to_s == "" ? "_" : cell.to_s}}
  end
end
