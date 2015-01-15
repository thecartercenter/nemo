require 'spec_helper'

describe Option do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:option, name_en: 'Foo', mission: nil)
    end

    context 'when no matching option exists in mission' do
      before do
        # Note that replicate will never really get called directly on Option, but we are testing in isolation here.
        @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
      end

      subject { @copy }
      its(:mission) { should eq @mission2 }
      its(:name_en) { should eq 'Foo'}
    end

    context 'when a matching option exists in mission' do
      before do
        @match = create(:option, name_en: 'Foo', mission: @mission2)
        @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
      end

      it 'should return match' do
        expect(@copy).to eq @match
      end
    end
  end

  describe 'clone' do
    # Option clone is not supported
  end

  describe 'promote with link' do
    before(:all) do
      @orig = create(:option, name_en: 'Foo', mission: @mission1)
      # Note that replicate will never really get called directly on Option, but we are testing in isolation here.
      @copy = @orig.replicate(mode: :promote, retain_link_on_promote: true)
    end

    it 'should create correct copy' do
      expect(@copy.mission).to be_nil
      expect(@copy.name_en).to eq 'Foo'
    end
  end
end
