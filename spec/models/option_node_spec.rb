require 'spec_helper'

describe OptionNode do
  before { @set = create(:option_set) }

  # context 'on create' do
  #   before do
  #     @root = create(:option_node, option_set: @set, rank: 1)
  #     @child = @root.children.create(rank: 1)
  #     @grandchild = @child.children.create(rank: 1)
  #   end
  #
  #   it 'should inherit option set from parent' do
  #     expect(@child.option_set).to eq @set
  #     expect(@grandchild.option_set).to eq @set
  #   end
  # end

  # describe 'ranks_changed?' do
  #   before do
  #     @root = FactoryGirl.create(:option_node, option_set: @set, rank: 1)
  #     @child1 = FactoryGirl.create(:option_node, option_set: @set, rank: 1, parent: @root)
  #     FactoryGirl.create(:option_node, option_set: @set, rank: 2, parent: @root)
  #     FactoryGirl.create(:option_node, option_set: @set, rank: 1, parent: @child1)
  #     FactoryGirl.create(:option_node, option_set: @set, rank: 2, parent: @child1)
  #   end
  #
  #   it 'should work recursively' do
  #   end
  # end

  describe 'creating from hash' do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: 'Dog')
      @oak = create(:option, name_en: 'Oak')
      @node = OptionNode.create!(
        'option' => nil,
        'option_set' => @set, # This only needs to be passed to root, which will propagate it.
        'children_attribs' => [{
          'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
          'children_attribs' => [
            { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
            { 'option_attribs' => { 'id' => @dog.id } } # Existing option
          ]
        }, {
          'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
          'children_attribs' => [
            { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} } },
            { 'option_attribs' => { 'id' => @oak.id, 'name_translations' => {'en' => 'White Oak'} } } # also change a name for this option
          ]
        }]
      )
    end

    it 'should be correct' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'White Oak']]])
    end
  end

  def expect_node(val, node = nil)
    if node.nil?
      node = @node
      val = [nil, val]
    end

    expect(node.option.try(:name)).to eq (val.is_a?(Array) ? val[0] : val)
    expect(node.option_set).to eq @set

    if val.is_a?(Array)
      children = node.children.order(:rank)
      expect(children.map(&:rank)).to eq (1..children.count).to_a # Contiguous ranks and correct count
      children.each_with_index { |c, i| expect_node(val[1][i], c) } # Recurse
    else
      expect(node.children).to be_empty
    end
  end
end
