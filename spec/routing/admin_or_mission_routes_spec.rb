require 'rails_helper'

describe 'router' do
  it 'routes admin mode forms' do
    expect(:get => '/en/admin/forms').to route_to(
      :controller => 'forms', :action => 'index', :locale => 'en', :mode => 'admin')
  end

  it 'routes admin mode forms even with mission_name' do
    # Note this seems wrong but will be caught after routing by the ApplicationController
    expect(:get => '/en/admin/mission123/forms').to route_to(
      :controller => 'forms', :action => 'index', :locale => 'en', :mode => 'admin', :mission_name => 'mission123')
  end

  it 'routes mission mode forms' do
    expect(:get => '/en/m/mission123/forms').to route_to(
      :controller => 'forms', :action => 'index', :locale => 'en', :mode => 'm', :mission_name => 'mission123')
  end

  it 'rejects forms with no mode' do
    expect(:get => '/en/forms').not_to be_routable
  end

  it 'routes user show in admin mode' do
    expect(:get => "/en/admin/users/1").to route_to(
      :controller => 'users', :action => 'show', :locale => 'en', :mode => 'admin', :id => '1')
  end

  it 'routes user show in mission mode' do
    expect(:get => "/en/m/mission123/users/1").to route_to(
      :controller => 'users', :action => 'show', :locale => 'en', :mode => 'm', :mission_name => 'mission123', :id => '1')
  end
end
