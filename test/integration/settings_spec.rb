require 'spec_helper'

# tests maintenance of settings across key actions
# timezone is used as a key test vector
describe 'Settings' do
  before do
    @admin = create(:user, :admin => true)
  end

  it "settings should be default on first load" do
    get('/en')
    follow_redirect!
    expect(response).to be_success

    # ensure default timezone got loaded
    expect(Time.zone.name).to eq(Setting::DEFAULTS[:timezone])
  end

  it "settings should be copied properly on update" do
    # login as admin
    login(@admin)

    # ensure timezone is normal
    assert_not_equal("Brisbane", Time.zone.name)

    # update timzeone to something whacky
    update_timezone_for_setting(get_mission.setting, 'Brisbane')

    # ensure timezone is now brisbane
    expect(Time.zone.name).to eq("Brisbane")
  end

  it "settings get created and saved for new mission" do
    # login admin, and set the timezone to something weird
    login(@admin)
    update_timezone_for_setting(get_mission.setting, 'Brisbane')
    expect(Time.zone.name).to eq('Brisbane')

    # create a new mission and ensure that a new setting object was created with the default timezone
    post(missions_path, :mission => {:name => 'Foo'})
    follow_redirect!
    expect(response).to be_success
    expect(Mission.find_by_name('Foo').setting.timezone).to eq(Setting::DEFAULTS[:timezone])

    # change to that mission and see that timezone changed
    get('/en/m/foo')
    expect(Time.zone.name).to eq(Setting::DEFAULTS[:timezone])
  end

  it "settings revert to defaults on logout" do
    login(@admin)

    # Switch to a mission with known funny timezone and make sure timezone not UTC.
    get(mission_root_path(:mission_name => get_mission.compact_name))
    assert_not_equal(Setting::DEFAULTS[:timezone], Time.zone.name)

    # logout and ensure timezone reverts to UTC
    logout
    expect(Time.zone.name).to eq(Setting::DEFAULTS[:timezone])
  end

  it "locales should get copied properly" do
    get_mission.setting.update_attributes!(:preferred_locales_str => "fr,ar")
    login(@admin)
    get(mission_root_path(:mission_name => get_mission.compact_name))
    expect(configatron.preferred_locales).to eq([:fr, :ar])
  end

  private
    def update_timezone_for_setting(setting, timezone)
      put(setting_path(setting, :mode => 'm', :mission_name => setting.mission.compact_name), :setting => {:timezone => timezone})
      follow_redirect!
      expect(response).to be_success
    end
end