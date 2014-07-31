require 'spec_helper'

describe 'footer' do
  describe 'sms adapter' do
    before do
      login(create(:user, admin: true))
    end

    context 'with no adapter set' do
      before do
        get_mission.setting.update_attributes!(outgoing_sms_adapter: nil)
      end

      it 'should say none' do
        get_s(mission_root_path(get_mission))
        assert_select("div#footer", /Outgoing SMS Provider:\s+\[None\]/m)
      end
    end

    context 'with an adapter set' do # One is set by default
      it 'should say adapter name' do
        get_s(mission_root_path(get_mission))
        assert_select("div#footer", /Outgoing SMS Provider:\s+IntelliSms/m)
      end
    end
  end
end