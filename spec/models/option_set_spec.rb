require 'spec_helper'

describe OptionSet do
  include OptionNodeSupport

  it 'should get constructed properly' do
    os = create(:option_set, multi_level: true)
    # This assertion checks that option_set, mission, and is_standard? get cascaded properly.
    expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]], os.root_node)
    expect(Option.count).to eq 6
    expect(OptionNode.count).to eq 7
  end

  it 'should get constructed properly if standard' do
    os = create(:option_set, is_standard: true)
    expect_node(['Cat', 'Dog'], os.root_node)
  end

  it 'should get updated properly' do
    os = create(:option_set)
    os.update_attributes!(children_attribs: OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS)
    expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]], os.reload.root_node)
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

  it 'should be destructible' do
    os = create(:option_set)
    os.destroy
    expect(OptionSet.exists?(os.id)).to be false
    expect(OptionNode.where(option_set_id: os.id).count).to eq 0
  end

  describe 'options' do
    before { @set = create(:option_set, multi_level: true) }

    it 'should delegate to option node child options' do
      expect(@set.root_node).to receive(:child_options)
      @set.options
    end
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
      set = create(:option_set, multi_level: true)
      expect(set.levels[0].name).to eq 'Kingdom'
      expect(set.levels[1].name).to eq 'Species'
    end
  end
end
