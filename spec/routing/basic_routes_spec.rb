require 'rails_helper'

describe 'router' do
  it 'routes root with locale' do
    expect(:get => '/en').to route_to(:controller => 'welcome', :action => 'index', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes root with locale and trailing slash' do
    expect(:get => '/en/').to route_to(:controller => 'welcome', :action => 'index', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes login with locale' do
    expect(:get => '/en/login').to route_to(:controller => 'user_sessions', :action => 'new', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'doesnt route login without locale' do
    expect(:get => '/login').not_to be_routable
  end

  it 'routes logout without locale' do
    expect(:delete => '/en/logout').to route_to(:controller => 'user_sessions', :action => 'destroy', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes edit profile' do
    expect(:get => '/en/users/1/edit').to route_to(:controller => 'users', :action => 'edit',
      :locale => 'en', :id => '1')
  end
end
