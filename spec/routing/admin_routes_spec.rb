require 'spec_helper'

describe 'router' do
  it 'routes admin root' do
    { :get => '/en/admin' }.should route_to(
      :controller => 'welcome', :action => 'index', :locale => 'en', :mode => 'admin')
  end

  it 'routes admin root without locale' do
    { :get => '/admin' }.should route_to(
      :controller => 'welcome', :action => 'index', :mode => 'admin')
  end

  it 'routes missions index' do
    { :get => '/en/admin/missions' }.should route_to(
      :controller => 'missions', :action => 'index', :locale => 'en', :mode => 'admin')
  end

  it 'rejects missions index in mission mode' do
    { :get => '/en/m/mission123/missions' }.should_not be_routable
  end

  it 'rejects mission id in admin mode' do
    { :get => '/en/admin/mission123/missions' }.should_not be_routable
  end
end
