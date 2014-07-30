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

  it 'must have at least one option' do
    os = build(:empty_option_set)
    os.save
    assert_match(/at least one/, os.errors[:options].join)
  end

  it 'should delegate ranks_changed? to root node' do
    os = create(:option_set)
    expect(os.root_node).to receive(:ranks_changed?)
    os.ranks_changed?
  end
end
