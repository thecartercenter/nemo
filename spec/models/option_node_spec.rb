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

  describe 'destroy' do
    before do
      @node = create(:option_node_with_children, option_set: @set)
      @option = @node.children[0].option
      @node.children[0].destroy
    end

    it 'should not destroy option' do
      expect(Option.exists?(@option)).to be_truthy
    end
  end

  describe 'option_level' do
    before do
      @node = create(:option_node_with_children, option_set: @set)
    end

    it 'should be nil for root' do
      expect(@node.level).to be_nil
    end

    it 'should be correct for first level' do
      subnode = @node.c[0]
      expect(subnode.option_set).to receive(:level).with(1).and_return(double(:name => 'Foo'))
      expect(subnode.level.name).to eq 'Foo'
    end

    it 'should be correct for second level' do
      subnode = @node.c[0].c[0]
      expect(subnode.option_set).to receive(:level).with(2).and_return(double(:name => 'Bar'))
      expect(subnode.level.name).to eq 'Bar'
    end
  end

  describe 'creating single level from hash' do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: 'Dog')
      @node = OptionNode.create!(
        'option' => nil,
        'option_set' => @set, # This only needs to be passed to root, which will propagate it.
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
          { 'option_attribs' => { 'id' => @dog.id, 'name_translations' => {'en' => 'Dog'} } }
        ]
      )
    end

    it 'should be correct' do
      expect_node(['Cat', 'Dog'])
    end
  end

  describe 'creating multilevel from hash' do
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

  describe 'updating from hash with no changes' do
    before do
      @node = create(:option_node_with_children, option_set: @set)
      @node.update_attributes!('children_attribs' => [{
          'id' => @node.c[0].id,
          'option_attribs' => { 'id' => @node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
          'children_attribs' => [
            {
              'id' => @node.c[0].c[0].id,
              'option_attribs' => { 'id' => @node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
            },
            {
              'id' => @node.c[0].c[1].id,
              'option_attribs' => { 'id' => @node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
            }
          ]
        }, {
          'id' => @node.c[1].id,
          'option_attribs' => { 'id' => @node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
          'children_attribs' => [
            {
              'id' => @node.c[1].c[0].id,
              'option_attribs' => { 'id' => @node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
            },
            {
              'id' => @node.c[1].c[1].id,
              'option_attribs' => { 'id' => @node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
            }
          ]
        }]
      )
    end

    it 'should still be correct' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
    end
  end

  describe 'updating from hash with changes' do
    before do
      @node = create(:option_node_with_children, option_set: @set)

      # Changes:
      # Move Cat from Animal to Plant (by deleting node and creating new)
      # Change name of Tulip to Tulipe.
      # Change name of Dog to Doge.
      # Move Tulip to rank 3.
      @node.update_attributes!('children_attribs' => [{
          'id' => @node.c[0].id,
          'option_attribs' => { 'id' => @node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
          'children_attribs' => [
            {
              'id' => @node.c[0].c[1].id,
              'option_attribs' => { 'id' => @node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Doge'} }
            }
          ]
        }, {
          'id' => @node.c[1].id,
          'option_attribs' => { 'id' => @node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
          'children_attribs' => [
            {
              'option_attribs' => { 'id' => @node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
            },
            {
              'id' => @node.c[1].c[1].id,
              'option_attribs' => { 'id' => @node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
            },
            {
              'id' => @node.c[1].c[0].id,
              'option_attribs' => { 'id' => @node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulipe'} }
            },
          ]
        }]
      )
    end

    it 'should be correct' do
      expect_node([['Animal', ['Doge']], ['Plant', ['Cat', 'Oak', 'Tulipe']]])
    end
  end

  describe 'destroying subtree and adding new subtree' do
    before do
      @node = create(:option_node_with_children, option_set: @set)

      @node.update_attributes!('children_attribs' => [{
          'id' => @node.c[1].id,
          'option_attribs' => { 'id' => @node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
          'children_attribs' => [
            {
              'id' => @node.c[1].c[0].id,
              'option_attribs' => { 'id' => @node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
            },
            {
              'id' => @node.c[1].c[1].id,
              'option_attribs' => { 'id' => @node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
            }
          ]
        },{
          'option_attribs' => { 'name_translations' => {'en' => 'Laser'} },
          'children_attribs' => [
            {
              'option_attribs' => { 'name_translations' => {'en' => 'Green'} }
            },
            {
              'option_attribs' => { 'name_translations' => {'en' => 'Red'} }
            }
          ]
        }]
      )
    end

    it 'should be correct' do
      expect_node([['Plant', ['Tulip', 'Oak']], ['Laser', ['Green', 'Red']]])
    end
  end

  describe 'destroying all' do
    before do
      @node = create(:option_node_with_children, option_set: @set)

      @node.update_attributes!('children_attribs' => [])
    end

    it 'should be correct' do
      expect_node([])
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
      expect(children.map(&:rank)).to eq (1..val[1].size).to_a # Contiguous ranks and correct count
      children.each_with_index { |c, i| expect_node(val[1][i], c) } # Recurse
    else
      expect(node.children).to be_empty
    end
  end
end
