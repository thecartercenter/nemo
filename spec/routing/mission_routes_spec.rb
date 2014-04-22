require 'spec_helper'

describe 'router' do
  it 'routes broadcasts with locale and prefix' do
    { :get => '/en/m/mission123/broadcasts' }.should route_to(
      :controller => 'broadcasts', :action => 'index', :locale => 'en', :mode => 'm', :mission_id => 'mission123')
  end

  it 'rejects invalid mission name' do
    { :get => '/en/m/mission!123/broadcasts' }.should_not be_routable
  end

  it 'rejects admin prefix' do
    { :get => '/en/admin/mission123/broadcasts' }.should_not be_routable
  end

  it 'routes without explicit locale' do
    { :get => '/m/mission123/broadcasts' }.should route_to(
      :controller => 'broadcasts', :action => 'index', :mode => 'm', :mission_id => 'mission123')
  end

  it 'routes with report namespace' do
    { :get => '/en/m/mission123/report/reports' }.should route_to(
      :controller => 'report/reports', :action => 'index', :locale => 'en', :mode => 'm', :mission_id => 'mission123')
  end

  it 'routes special info-window route' do
    { :get => '/en/m/mission123/info-window' }.should route_to(
      :controller => 'welcome', :action => 'info_window', :locale => 'en', :mode => 'm', :mission_id => 'mission123')
  end

  it 'routes mission root' do
    # Note this will also route a mistaken URL like /en/m/broadcasts, but that's the expected behavior
    { :get => '/en/m/mission123' }.should route_to(
      :controller => 'welcome', :action => 'index', :locale => 'en', :mode => 'm', :mission_id => 'mission123')
  end

  it 'rejects if missing mission and prefix' do
    { :get => '/en/broadcasts' }.should_not be_routable
  end

  it 'rejects if missing locale, mission and prefix' do
    { :get => '/broadcasts' }.should_not be_routable
  end

  it 'routes import standard' do
    { :post => '/en/m/mission123/option-sets/import-standard' }.should route_to(
      :controller => 'option_sets', :action => 'import_standard', :locale => 'en',
        :mode => 'm', :mission_id => 'mission123')
  end
end
