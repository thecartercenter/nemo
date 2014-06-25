require 'spec_helper'

describe 'router' do
  it 'routes root with locale' do
    { :get => '/en' }.should route_to(:controller => 'welcome', :action => 'index', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes root with locale and trailing slash' do
    { :get => '/en/' }.should route_to(:controller => 'welcome', :action => 'index', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes login with locale' do
    { :get => '/en/login' }.should route_to(:controller => 'user_sessions', :action => 'new', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'doesnt route login without locale' do
    { :get => '/login' }.should_not be_routable
  end

  it 'routes logout without locale' do
    { :delete => '/en/logout' }.should route_to(:controller => 'user_sessions', :action => 'destroy', :locale => 'en', :mode => nil, :mission_name => nil)
  end

  it 'routes proxy requests without locale' do
    { :get => '/proxies/geocoder' }.should route_to(:controller => 'proxies', :action => 'geocoder')
  end

  it 'routes edit profile' do
    { :get => '/en/users/1/edit' }.should route_to(:controller => 'users', :action => 'edit',
      :locale => 'en', :mode => nil, :mission_name => nil, :id => '1')
  end
end
