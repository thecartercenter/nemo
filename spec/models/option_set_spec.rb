require 'spec_helper'

describe OptionSet do
  it 'must have at least one option' do
    os = build(:option_set, :option_names => [])
    os.save
    assert_match(/at least one/, os.errors[:options].join)
  end

  it 'should delegate ranks_changed? to root node' do
    os = create(:option_set)
    expect(os.root_node).to receive(:ranks_changed?)
    os.ranks_changed?
  end
end
