# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Add this to load Capybara integration:
require 'capybara/rspec'
require 'capybara/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.infer_spec_type_from_file_location!

  config.include AssertDifference
end

# Encodes credentials for basic auth
def encode_credentials(username, password)
  "Basic #{Base64.encode64("#{username}:#{password}")}"
end

def submit_j2me_response(params)
  raise 'form must have version' unless @form.current_version

  # Add all the extra stuff that J2ME adds to the data hash
  params[:data]['id'] = @form.id.to_s
  params[:data]['uiVersion'] = '1'
  params[:data]['version'] = @form.current_version.sequence
  params[:data]['name'] = @form.name
  params[:data]['xmlns:jrm'] = 'http://dev.commcarehq.org/jr/xforms'
  params[:data]['xmlns'] = "http://openrosa.org/formdesigner/#{@form.current_version.sequence}"

  # If we are doing a normally authenticated submission, add credentials.
  headers = params[:auth] ? {'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password')} : {}

  post(@submission_url, params.slice(:data), headers)
end

# helper method to parse json and make keys symbols
def parse_json(body)
  JSON.parse(body, symbolize_names: true)
end

# Currently duplicated in test/test_helper until it becomes obvious how to refactor.
def login(user)
  login_without_redirect(user)
  follow_redirect!
  assert_response(:success)
  user.reload # Some stuff may have changed in database during login process
end

def login_without_redirect(user)
  post('/en/user-session', :user_session => {:login => user.login, :password => 'password'})
end

def logout
  delete('/en/user-session')
  follow_redirect!
end

def do_api_request(endpoint, params = {})
  params[:user] ||= @api_user
  params[:mission_name] ||= @mission.compact_name

  path_args = [{:mission_name => params[:mission_name]}]
  path_args.unshift(params[:obj]) if params[:obj]
  path = send("api_v1_#{endpoint}_path", *path_args)

  get path, params[:params], {'HTTP_AUTHORIZATION' => "Token token=#{params[:user].api_key}"}
end

def get_s(*args)
  get *args
  assert_response(:success)
end

def expect_node(val, node = nil)
  if node.nil?
    node = @node
    val = [nil, val]
  end

  expect(node.option.try(:name)).to eq (val.is_a?(Array) ? val[0] : val)
  expect(node.option_set).to eq @set

  if val.is_a?(Array)
    children = node.children.order(:rank)
    expect(children.map(&:rank)).to eq (1..val[1].size).to_a # Contiguous ranks and correct count
    children.each_with_index { |c, i| expect_node(val[1][i], c) } # Recurse
  else
    expect(node.children).to be_empty
  end
end

# This is a standard set of changes to the option_node_with_grandchildren factory object.
# Changes:
# Move Cat from Animal to Plant (by deleting node and creating new)
# Change name of Tulip to Tulipe.
# Change name of Dog to Doge.
# Move Tulip to rank 3.
def standard_changeset(node)
  {
    'children_attribs' => [{
      'id' => node.c[0].id,
      'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
      'children_attribs' => [
        {
          'id' => node.c[0].c[1].id,
          'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Doge'} }
        }
      ]
    }, {
      'id' => node.c[1].id,
      'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
      'children_attribs' => [
        {
          'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
        },
        {
          'id' => node.c[1].c[1].id,
          'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
        },
        {
          'id' => node.c[1].c[0].id,
          'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulipe'} }
        },
      ]
    }]
  }
end

# What a hash submission would like like for the option_node_with_grandchildren object with no changes.
def no_change_changeset(node)
  {
    'children_attribs' => [{
      'id' => node.c[0].id,
      'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
      'children_attribs' => [
        {
          'id' => node.c[0].c[0].id,
          'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
        },
        {
          'id' => node.c[0].c[1].id,
          'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
        }
      ]
    }, {
      'id' => node.c[1].id,
      'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
      'children_attribs' => [
        {
          'id' => node.c[1].c[0].id,
          'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
        },
        {
          'id' => node.c[1].c[1].id,
          'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
        }
      ]
    }]
  }
end
