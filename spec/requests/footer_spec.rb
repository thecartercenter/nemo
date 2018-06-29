require 'rails_helper'

describe 'footer' do
  describe 'sms adapter', :sms do
    before do
      login(create(:user, admin: true))
    end

    context 'with no adapter set' do
      before do
        get_mission.setting.update_attributes!(default_outgoing_sms_adapter: nil)
      end

      it 'should say none' do
        get_s(mission_root_path(mission_name: get_mission.compact_name))
        assert_select("div#footer", /Outgoing SMS Provider:\s+\[None\]/m)
      end
    end

    context 'with an adapter set' do # One is set by default
      it 'should say adapter name' do
        get_s(mission_root_path(mission_name: get_mission.compact_name))
        assert_select("div#footer", /Outgoing SMS Provider:\s+Twilio/m)
      end
    end
  end
end
