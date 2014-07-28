require 'spec_helper'

describe Option do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'replication' do
    before do
      @orig = create(:option_node_with_grandchildren, is_standard: true)
      @node = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
    end

    describe 'on create' do
      subject { @node }
      its(:mission) { should eq @mission2 }
      its(:standard) { should eq @orig }
      its(:is_standard) { should be_falsey }
      its(:option) { should be_nil } # Because it's root

      it 'should have copies of orig options' do
        expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
        expect(@node.c[1].c[1].standard).to eq @orig.c[1].c[1]
        expect(@node.c[1].c[1].option.standard).to eq @orig.c[1].c[1].option
      end
    end
  end
end
