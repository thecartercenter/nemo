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

    subject { @node }

    it 'should be correct' do
      expect(@node.option_id).to be_nil
      expect(@node.descendants.count).to eq 6
      expect(@node.children[0].children[0].option.name).to eq 'Cat'
    end
  end
end
