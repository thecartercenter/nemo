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
    expect(node.is_standard?).to eq options[:root].is_standard?

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
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Doge'} }
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
          },
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulipe'} }
          },
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
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
          },
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
          },
          {
            'option_attribs' => { 'name_translations' => {'en' => 'Ocelot'} }
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
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
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
          },
          {
            'id' => node.c[0].c[0].id,
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
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
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
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
            'option_attribs' => { 'id' => node.c[0].c[0].option_id, 'name_translations' => {'en' => 'Cat'} }
          },
          {
            'id' => node.c[0].c[1].id,
            'option_attribs' => { 'id' => node.c[0].c[1].option_id, 'name_translations' => {'en' => 'Dog'} }
          }
        ]
      }, {
        'id' => node.c[1].id,
        'option_attribs' => { 'id' => node.c[1].option_id, 'name_translations' => {'en' => 'Plant'} },
        'children_attribs' => [
          {
            'id' => node.c[1].c[0].id,
            'option_attribs' => { 'id' => node.c[1].c[0].option_id, 'name_translations' => {'en' => 'Tulip'} }
          },
          {
            'id' => node.c[1].c[1].id,
            'option_attribs' => { 'id' => node.c[1].c[1].option_id, 'name_translations' => {'en' => 'Oak'} }
          }
        ]
      }]
    }
  end

  WITH_GRANDCHILDREN_ATTRIBS = [{
    'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
    'children_attribs' => [
      { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
      { 'option_attribs' => { 'name_translations' => {'en' => 'Dog'} } }
    ]
  }, {
    'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
    'children_attribs' => [
      { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} } },
      { 'option_attribs' => { 'name_translations' => {'en' => 'Oak'} } }
    ]
  }]
end
