module ReportTestHelper

  def prep_objects
    Language.generate
    Report::ResponseAttribute.generate
    Report::Aggregation.generate
    [Question, Questioning, Answer, Place, Form, User].each{|k| k.delete_all}
    @qs = {}; @rs = []; @places = {}; @forms = {}; @opt_sets = {}; @users = {}
  end
  
  def create_report(options)
    agg = Report::Aggregation.find_by_name(options.delete(:agg))
    Report::Report.create!(options.merge(:name => "TheReport", :aggregation => agg))
  end
  
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
  
  def user
    @users[:test] ||= User.create!(:login => "test", :name => "Test",
      :email => "test@example.com", :role_id => 1, :active => true, 
      :language => Language.english, :password => "changeme", :password_confirmation => "changeme")
  end

  def create_question(params)
    QuestionType.generate
    
    # create default form if necessary
    params[:forms] ||= [create_form(:name => "f")]  
  
    q = Question.new(:name_eng => params[:code], :code => params[:code], 
      :question_type_id => QuestionType.find_by_name(params[:type]).id)
  
    # set the option set if type is select_one
    q.option_set = params[:option_set] || @opt_sets.first[1] if params[:type] == "select_one"
  
    # create questionings for each form
    params[:forms].each{|f| q.questionings.build(:form => f)}
  
    # save and store in hash
    q.save!
    @qs[params[:code].to_sym] = q
  end

  def create_response(params)
    ans = params.delete(:answers) || {}
    r = Response.new({:reviewed => true, :form => @forms[:f] || create_form(:name => "f"), 
      :observed_at => Time.now, :user => user}.merge(params))
    ans.each_pair do |code,value|
      qing = @qs[code].questionings.first
      case qing.question.type.name
      when "select_one"
        r.answers.build(:questioning_id => qing.id, :option => qing.question.options.find{|o| o.name_eng == value})
      else
        r.answers.build(:questioning_id => qing.id, :value => value)
      end
    end
    r.save!
    @rs << r
    r
  end

  def set_eastern_timezone
    Time.zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
  end

  def assert_report(report, *expected)
    report.run
    if expected.first.nil?
      assert_nil(report.data) 
    else
      raise "Report errors: " + report.errors.full_messages.join(", ") unless report.errors.empty?
      raise "Missing headers" if report.headers.nil? || report.headers[:col].nil? || report.headers[:row].nil?
      raise "Bad data array" if report.data.nil? || report.data.empty?
      actual = [report.headers[:col].collect{|h| h[:name]}]
      # generate the expected value
      report.data.each_with_index do |row, i| 
        rh = report.headers[:row][i] ? Array.wrap(report.headers[:row][i][:name]) : []
        actual += [rh + row.collect{|x| x.to_s}]
      end
      assert_equal(expected, actual)
    end
  end
end