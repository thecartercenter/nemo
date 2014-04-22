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

  it 'routes ODK form list' do
    { :get => '/m/mission123/formList' }.should route_to(
      :controller => 'forms', :action => 'index', :mode => 'm', :mission_id => 'mission123', :format => 'xml')
  end

  it 'routes ODK form download' do
    { :get => '/m/mission123/forms/99' }.should route_to(
      :controller => 'forms', :action => 'show', :mode => 'm', :mission_id => 'mission123',
        :id => '99', :format => 'xml')
  end

  it 'routes ODK submission' do
    { :post => '/m/mission123/submission' }.should route_to(
      :controller => 'responses', :action => 'create', :mode => 'm', :mission_id => 'mission123',
        :format => 'xml')
  end

  it 'rejects ODK submission without mission' do
    { :post => '/submission' }.should_not be_routable
  end
end
