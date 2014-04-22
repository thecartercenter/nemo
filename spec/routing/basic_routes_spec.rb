require 'spec_helper'

describe 'router' do
  it 'routes root' do
    { :get => '/' }.should route_to(:controller => 'welcome', :action => 'index')
  end

  it 'routes root with locale' do
    { :get => '/en' }.should route_to(:controller => 'welcome', :action => 'index', :locale => 'en')
  end

  it 'routes root with locale and trailing slash' do
    { :get => '/en/' }.should route_to(:controller => 'welcome', :action => 'index', :locale => 'en')
  end

  it 'routes login with locale' do
    { :get => '/en/login' }.should route_to(:controller => 'user_sessions', :action => 'new', :locale => 'en')
  end

  it 'routes login without locale' do
    { :get => '/login' }.should route_to(:controller => 'user_sessions', :action => 'new')
  end

  it 'routes logout without locale' do
    { :delete => '/en/logout' }.should route_to(:controller => 'user_sessions', :action => 'destroy', :locale => 'en')
  end

  it 'routes proxy requests without locale' do
    { :get => '/proxies/geocoder' }.should route_to(:controller => 'proxies', :action => 'geocoder')
  end
end
