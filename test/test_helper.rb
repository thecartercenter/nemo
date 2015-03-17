ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'authlogic/test_case'

# Share spec support files.
require File.expand_path('../../spec/support/option_node_support', __FILE__)

class ActiveSupport::TestCase

  setup :set_url_options

  ## MEMORY OPTIMIZATION FOR TESTING
  setup :begin_gc_deferment
  teardown :reconsider_gc_deferment
  teardown :scrub_instance_variables

  DEFERRED_GC_THRESHOLD = (ENV['DEFER_GC'] || 1.0).to_f

  @@last_gc_run = Time.now
  @@reserved_ivars = %w(@fixture_connections @loaded_fixtures @test_passed @fixture_cache @method_name @_assertion_wrapped @_result).map(&:to_sym)

  self.use_transactional_fixtures = false

  setup do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

  # runs the block outside a transaction, evading the default database cleaning strategy
  # this is slower, but needed sometimes
  def no_transaction
    # close the current transaction
    DatabaseCleaner.clean

    # change strategy to truncation for now
    DatabaseCleaner.strategy = :truncation

    yield

    # remove whatever was added in block
    DatabaseCleaner.clean

    # go back to transaction method
    DatabaseCleaner.strategy = :transaction
  end

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
    if defined?(app)
      app.default_url_options = { :locale => I18n.locale || I18n.default_locale, :mode => nil }
    end
  end

  # logs in the given user
  # we assume that the password is 'password'
  def login(user)
    post(user_session_path(:locale => 'en'), :user_session => {:login => user.login, :password => "password"})
    follow_redirect!
    assert_response(:success)
    user.reload # Some stuff may have changed in database during login process
  end

  # logs out the current user and follows redirect
  def logout
    delete(user_session_path(:locale => 'en'))
    follow_redirect!
    assert_response(:success)
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

require "mocha/setup"
