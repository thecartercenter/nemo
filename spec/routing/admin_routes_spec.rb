require 'rails_helper'

describe 'router' do
  it 'routes admin root' do
    expect(:get => '/en/admin').to route_to(
      :controller => 'welcome', :action => 'index', :locale => 'en', :mode => 'admin', :mission_name => nil)
  end

  it 'doesnt route admin root without locale' do
    expect(:get => '/admin').not_to be_routable
  end

  it 'routes missions index' do
    expect(:get => '/en/admin/missions').to route_to(
      :controller => 'missions', :action => 'index', :locale => 'en', :mode => 'admin', :mission_name => nil)
  end

  it 'rejects missions index in mission mode' do
    expect(:get => '/en/m/mission123/missions').not_to be_routable
  end

  it 'rejects mission id in admin mode' do
    expect(:get => '/en/admin/mission123/missions').not_to be_routable
  end
end
