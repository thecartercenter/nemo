require 'spec_helper'

describe OptionSet do
  it 'should get constructed properly' do
    os = create(:option_set)
    # This assertion checks that option_set, mission, and is_standard? get cascaded properly.
    expect_node(['Cat', 'Dog'], os.root_node)
  end

  it 'should get constructed properly if standard' do
    os = create(:option_set, is_standard: true)
    expect_node(['Cat', 'Dog'], os.root_node)
  end

  it 'should get updated properly' do
    os = create(:option_set)
    os.update_attributes!(children_attribs: OPTION_NODE_WITH_GRANDCHILDREN_ATTRIBS)
    expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]], os.root_node)
  end

  it 'should delegate ranks_changed? to root node' do
    os = create(:option_set)
    expect(os.root_node).to receive(:ranks_changed?)
    os.ranks_changed?
  end

  it 'should delegate multi_level? to root node' do
    os = create(:option_set)
    expect(os.root_node).to receive(:has_grandchildren?)
    os.multi_level?
  end

  describe 'core_changed?' do
    before { @set = create(:option_set) }

    it 'should return true if name changed' do
      @set.name = 'Foobar'
      expect(@set.core_changed?).to eq true
    end

    it 'should return false if name didnt change' do
      expect(@set.core_changed?).to eq false
    end
  end

  describe 'levels' do
    it 'should be nil for single level set' do
      set = create(:option_set)
      expect(set.levels).to be_nil
    end

    it 'should be correct for multi level set' do
      set = create(:multilevel_option_set)
      expect(set.levels[0].name).to eq 'Kingdom'
      expect(set.levels[1].name).to eq 'Species'
    end
  end
end
