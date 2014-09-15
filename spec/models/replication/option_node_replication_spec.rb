require 'spec_helper'

describe OptionNode do
  include OptionNodeSupport

  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
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

    describe 'on update' do
      before do
        @oak_node_copy = @node.c[1].c[1]
        @orig.assign_attributes(standard_changeset(@orig))
        @orig.save_and_rereplicate!
      end

      it 'should have replicated changes and removed oak node copy' do
        expect_node([['Animal', ['Doge']], ['Plant', ['Cat', 'Tulipe']]])
        expect(OptionNode.exists?(@oak_node_copy)).to be false
      end
    end

    describe 'on destroy' do
      before do
        @option_copy = @node.c[0].c[0].option
        @orig.destroy_with_copies
      end

      it 'should destroy copies of nodes but not options' do
        expect(OptionNode.exists?(@node)).to be_falsey
        expect(Option.exists?(@option_copy)).to be_truthy
      end
    end
  end

  describe 'promote' do
    before(:all) do
      @orig = create(:option_node_with_grandchildren, mission: @mission1)
      @node = @orig.replicate(mode: :promote, retain_link_on_promote: true)
    end

    it 'should create a correct copy' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
      expect(@node.mission).to be_nil
      expect(@node.is_standard).to eq true
      expect(@node.standard).to be_nil
    end

    it 'should retain links' do
      expect(@orig.reload.standard).to eq @node
      expect(@orig.c[0].standard).to eq @node.c[0]
    end
  end

  describe 'clone' do
    before(:all) do
      @orig = create(:option_node_with_grandchildren, mission: @mission1)
      @node = @orig.replicate(mode: :clone)
    end

    it 'should make correct copy' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
      expect(@node.mission).to eq @mission1
      expect(@node.is_standard).to eq false
      expect(@node.standard).to be_nil
    end

    it 'should reuse options but not nodes' do
      expect(@node.c[0].option).to eq @orig.c[0].option
      expect(@node.c[0]).not_to eq @orig.c[0]
    end
  end
end
