require 'spec_helper'

describe Setting do
  describe 'load_for_mission' do
    shared_examples_for 'load_for_mission' do
      context 'when there are no existing settings' do
        before do
          get_mission.setting.destroy
        end

        it 'should create one with default values' do
          setting = Setting.load_for_mission(mission)
          expect(setting.new_record?).to be_falsey
          expect(setting.mission).to eq mission
          expect(setting.timezone).to eq Setting::DEFAULTS[:timezone]
        end
      end

      context 'when a setting exists' do
        before { Setting.load_for_mission(mission).update_attributes!(:preferred_locales => [:fr]) }

        it 'should load it' do
          setting = Setting.load_for_mission(mission)
          expect(setting.preferred_locales).to eq [:fr]
        end

        after do
          I18n.locale = :en
        end
      end
    end

    context 'for null mission' do
      let(:mission) { nil }
      it_should_behave_like 'load_for_mission'
    end

    context 'for mission' do
      let(:mission) { get_mission }
      it_should_behave_like 'load_for_mission'
    end
  end
end
