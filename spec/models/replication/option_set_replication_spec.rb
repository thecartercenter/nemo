require 'spec_helper'

describe OptionSet do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:multilevel_option_set, is_standard: true)
      @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
    end

    describe 'on create' do
      it 'should be copied properly' do
        expect(@copy.mission).to eq @mission2
        expect(@copy.name).to eq @orig.name
        expect(@copy.standard).to eq @orig
        expect(@copy.is_standard).to eq false
        expect(@copy.total_options).to eq 6
      end
    end
  end
end
