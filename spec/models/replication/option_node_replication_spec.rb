require 'spec_helper'

describe OptionNode do
  include OptionNodeSupport

  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:option_node_with_grandchildren)
      @node = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
    end

    subject { @node }
    its(:mission) { should eq @mission2 }
    its(:option) { should be_nil } # Because it's root
  end

  describe 'promote' do
    before(:all) do
      @orig = create(:option_node_with_grandchildren, mission: @mission1)
      @node = @orig.replicate(mode: :promote, retain_link_on_promote: true)
    end

    it 'should create a correct copy' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
      expect(@node.mission).to be_nil
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
    end

    it 'should reuse options but not nodes' do
      expect(@node.c[0].option).to eq @orig.c[0].option
      expect(@node.c[0]).not_to eq @orig.c[0]
    end
  end
end
