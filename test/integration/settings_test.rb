require 'test_helper'

# tests maintenance of settings across key actions
# timezone is used as a key test vector
class SettingsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
  end
  
  test "settings should be default on first load" do 
    get('/')
    follow_redirect!
    assert_response(:success)
    
    # ensure default timezone got loaded
    assert_equal(Setting::DEFAULTS[:timezone], Time.zone.name)
    
    # ensure no setting with nil mission saved
    assert_nil(Setting.where(:mission_id => nil).first)
  end
  
  test "settings should be copied properly on update" do
    # login as admin
    login(@admin)
    
    m = get_mission
    
    # ensure timezone is normal
    assert_not_equal("Brisbane", Time.zone.name)
    
    # update timzeone to something whacky
    update_timezone_for_setting(m.setting, 'Brisbane')
    
    # ensure timezone is now brisbane
    assert_equal("Brisbane", Time.zone.name)
  end
  
  test "settings get created and saved for new mission" do
    # login admin, and set the timezone to something weird
    login(@admin)
    update_timezone_for_setting(@admin.current_mission.setting, 'Brisbane')
    assert_equal('Brisbane', Time.zone.name)
    
    # create a new mission and ensure that a new setting object was created with the default timezone
    post(missions_path(:admin_mode => 'admin'), :mission => {:name => 'Foo'})
    follow_redirect!
    assert_response(:success)
    assert_equal(Setting::DEFAULTS[:timezone], Mission.find_by_name('Foo').setting.timezone)

    # change to that mission and see that timezone changed
    change_mission(@admin, Mission.find_by_name('foo'))
    assert_equal(Setting::DEFAULTS[:timezone], Time.zone.name)
  end
  
  test "settings for default mission get copied on login" do
    # set the user's current mission to a mission with a known weird timezone
    @admin.current_mission = get_mission
    @admin.save!

    # the @admin's current_mission settings timezone should not be UTC
    assert_not_equal(Setting::DEFAULTS[:timezone], @admin.current_mission.setting.timezone)

    # login the admin
    login(@admin)
    
    # and therefore the current timezone should also not be UTC
    assert_not_equal(Setting::DEFAULTS[:timezone], Time.zone.name)
  end
  
  test "settings revert to defaults on logout" do
    # login admin and make sure timezone not default
    login(@admin)
    assert_not_equal(Setting::DEFAULTS[:timezone], Time.zone.name)
    
    # logout and ensure timezone reverts to UTC
    logout
    assert_equal(Setting::DEFAULTS[:timezone], Time.zone.name)
  end
  
  test "locales should get copied properly" do
    get_mission.setting.update_attributes!(:preferred_locales_str => "fr,ar")
    login(@admin)
    assert_equal([:fr, :ar], configatron.preferred_locales)
  end
  
  private
    def update_timezone_for_setting(setting, timezone)
      put(setting_path(setting), :setting => {:timezone => timezone})
      follow_redirect!
      assert_response(:success)
    end
  
end