ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase

  setup :set_url_options

  ## MEMORY OPTIMIZATION FOR TESTING
  setup :begin_gc_deferment
  teardown :reconsider_gc_deferment
  teardown :scrub_instance_variables

  DEFERRED_GC_THRESHOLD = (ENV['DEFER_GC'] || 1.0).to_f

  @@last_gc_run = Time.now
  @@reserved_ivars = %w(@fixture_connections @loaded_fixtures @test_passed @fixture_cache @method_name @_assertion_wrapped @_result).map(&:to_sym)

  def begin_gc_deferment
    GC.disable if DEFERRED_GC_THRESHOLD > 0
  end

  def reconsider_gc_deferment
    if DEFERRED_GC_THRESHOLD > 0 && Time.now - @@last_gc_run >= DEFERRED_GC_THRESHOLD
      GC.enable
      GC.start
      GC.disable

      @@last_gc_run = Time.now
    end
  end

  def scrub_instance_variables
    (instance_variables - @@reserved_ivars).each do |ivar|
      instance_variable_set(ivar, nil)
    end
  end

  def clear_objects(*args)
    args.each{|k| k.delete_all}
  end

  # sets the url options for integration tests
  # this is also done in application_controller but needs to be done here too for some reason
  def set_url_options
    app.default_url_options = { :locale => I18n.locale, :admin_mode => nil } if defined?(app)
  end

  # logs in the given user
  # we assume that the password is 'password'
  def login(user)
    post(user_session_path, :user_session => {:login => user.login, :password => "password"})
    follow_redirect!
    assert_response(:success)

    # reload the user since some stuff may have changed in database (e.g. current_mission) during login process
    user.reload
  end

  # logs out the current user and follows redirect
  def logout
    delete(user_session_path)
    follow_redirect!
    assert_response(:success)
  end

  # changes the current mission for the session
  def change_mission(user, mission)
    put(user_path(@admin), :user => {:current_mission_id => mission.id})
    follow_redirect!
    assert_response(:success)
  end

  # helper that sets up a new form with the given parameters
  def setup_form(options)
    # default question required option
    options[:required] ||= false
    options[:mission] ||= get_mission

    @form = FactoryGirl.create(:form, :smsable => true, :mission => options[:mission])
    options[:questions].each do |type|
      # create the question
      q = FactoryGirl.build(:question, :code => "q#{rand(1000000)}", :qtype_name => type, :mission => options[:mission])

      # add an option set if required
      if %w(select_one select_multiple).include?(type)
        # put options in weird order to ensure the order stuff works ok
        q.option_set = FactoryGirl.create(:option_set, :name => "Options", :option_names => %w(A B C D E), :mission => options[:mission])
      end

      q.save!

      # add it to the form
      @form.questionings.create(:question => q, :required => options[:required])
    end
    @form.publish!
    @form.reload
  end

  # encodes credentials for basic auth
  def encode_credentials(username, password)
    "Basic #{Base64.encode64("#{username}:#{password}")}"
  end

  def get_success(*params)
    get(*params)
    assert_response(:success)
  end

  def assert_access_denied
    assert_response(302)
    assert_not_nil(assigns(:access_denied), "access should have been denied")
  end

  # checks that roles are as specified
  # roles should be an array of pairs e.g. [[mission1, role1], [mission2, role2]]
  def assert_roles(expected, user)
    expected = [expected] unless expected.empty? || expected[0].is_a?(Array)
    actual = user.roles
    expected.each do |r|
      assert_equal(r[1].to_s, actual[r[0]])
    end
  end
end
