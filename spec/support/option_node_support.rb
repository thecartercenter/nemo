module OptionNodeSupport
  def expect_node(val, node = nil, options = {})
    unless options[:recursed]
      node ||= @node
      val = [nil, val]
      options[:root] = node
    end

    expect(node.option.try(:name)).to eq (val.is_a?(Array) ? val[0] : val)
    expect(node.option_set).to eq options[:root].option_set
    expect(node.mission).to eq options[:root].mission

    if val.is_a?(Array)
      children = node.children.order(:rank)
      expect(children.map(&:rank)).to eq (1..val[1].size).to_a # Contiguous ranks and correct count
      options[:recursed] = true
      children.each_with_index { |c, i| expect_node(val[1][i], c, options) } # Recurse
    else
      expect(node.children).to be_empty
    end
  end

  # This is a standard set of changes to the option_node_with_grandchildren factory object.
  # Changes:
  # Move Cat from Animal to Plant.
  # Change name of Tulip to Tulipe.
  # Change name of Dog to Doge.
  # Delete Oak.
  # Move Tulip to rank 1.
  def standard_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Doge'} },
            'children_attribs' => 'NONE'
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulipe'} },
            'children_attribs' => 'NONE'
          },
        ]
      }]
    }
  end

  # Moves Cat and Dog from Animal to Plant.
  def move_node_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => 'NONE'
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} },
            'children_attribs' => 'NONE'
          }
        ]
      }]
    }
  end

  # Adds one option only to standard multilevel option node.
  def additive_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} },
            'children_attribs' => 'NONE'
          },
          {
            'option_attribs' => { 'name_translations' => {'en' => 'Ocelot'} },
            'children_attribs' => 'NONE'
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} },
            'children_attribs' => 'NONE'
          }
        ]
      }]
    }
  end

  # Changes the ranks of options but does not remove or add.
  def reorder_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} },
            'children_attribs' => 'NONE'
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} },
            'children_attribs' => 'NONE'
          }
        ]
      }]
    }
  end

  # Removes one option from the standard option set.
  def removal_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} },
            'children_attribs' => 'NONE'
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} },
            'children_attribs' => 'NONE'
          }
        ]
      }]
    }
  end

  # What a hash submission would like like for the option_node_with_grandchildren object with no changes.
  def no_change_changeset(node)
    {
      'children_attribs' => [{
        'id' => node.c[0].id,
        'option_attribs' => { 'id' => node.c[0].option_id, 'name_translations' => {'en' => 'Animal'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} },
            'children_attribs' => 'NONE'
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} },
            'children_attribs' => 'NONE'
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} },
            'children_attribs' => 'NONE'
          }
        ]
      }]
    }
  end

  WITH_GRANDCHILDREN_ATTRIBS = [{
    'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
    'children_attribs' => [
      { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} }, 'children_attribs' => 'NONE' },
      { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} }, 'children_attribs' => 'NONE' }
    ]
  }, {
    'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
    'children_attribs' => [
      { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} }, 'children_attribs' => 'NONE' },
      { 'option_attribs' => { 'name_translations' => {'en' => 'Oak'} }, 'children_attribs' => 'NONE' }
    ]
  }]

  WITH_GREAT_GRANDCHILDREN_ATTRIBS = [{
    'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
    'children_attribs' => [
      {
        'option_attribs' => { 'name_translations' => {'en' => 'Vertebrate'} },
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} }, 'children_attribs' => 'NONE' },
          { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} }, 'children_attribs' => 'NONE' }
        ]
      },
      {
        'option_attribs' => { 'name_translations' => {'en' => 'Invertebrate'} },
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Lobster'} }, 'children_attribs' => 'NONE' },
          { 'option_attribs' => { 'name_translations' => {'en' => 'Jellyfish'} }, 'children_attribs' => 'NONE' }
        ]
      }
    ]
  }, {
    'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
    'children_attribs' => [
      {
        'option_attribs' => { 'name_translations' => {'en' => 'Tree'} },
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Oak'} }, 'children_attribs' => 'NONE' },
          { 'option_attribs' => { 'name_translations' => {'en' => 'Pine'} }, 'children_attribs' => 'NONE' }
        ]
      },
      {
        'option_attribs' => { 'name_translations' => {'en' => 'Flower'} },
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} }, 'children_attribs' => 'NONE' },
          { 'option_attribs' => { 'name_translations' => {'en' => 'Daisy'} }, 'children_attribs' => 'NONE' }
        ]
      }
    ]
  }]
end
