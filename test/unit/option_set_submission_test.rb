require 'test_helper'

# tests for submission of option sets via JSON
class OptionSetSubmissionTest < ActiveSupport::TestCase

  test "creating a multilevel option set via json should work" do
    # we use a mixture of existing and new options
    dog = Option.create(:name_en => 'Dog', :mission => get_mission)
    oak = Option.create(:name_en => 'Oak', :mission => get_mission)

    os = OptionSet.new.update_from_json!({
      'name' => 'foo',
      'mission' => get_mission,
      'multi_level' => true,
      'geographic' => false,
      '_option_levels' => [
        { 'en' => 'Kingdom', 'fr' => 'Royaume' },
        { 'en' => 'Species' }
      ],
      '_optionings' => [
        {
          'option' => {
            'name_translations' => {'en' => 'Animal'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Cat'}
              }
            },
            {
              'option' => {
                'id' => dog.id
              }
            }
          ]
        },
        {
          'option' => {
            'name_translations' => {'en' => 'Plant'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Tulip'}
              }
            },
            {
              'option' => {
                'id' => oak.id,
                # also change a name for this option
                'name_translations' => {'en' => 'White Oak'}
              }
            }
          ]
        }
      ]
    })

    os.reload

    assert_levels(%w(Kingdom Species), os)
    assert_options([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'White Oak']]], os)
  end

  private

    # checks that option set levels matches the given names
    def assert_levels(expected, os)
      assert_equal(expected, os.option_levels.map(&:name_en))

      # check that all have mission and correct option set reference
      assert_equal([os.mission], os.option_levels.map(&:mission).uniq)
      assert_equal([os], os.option_levels.map(&:option_set).uniq)
    end

    # checks that option set matches the given structure
    # recursive method
    def assert_options(expected, os, node = nil, depth = nil, parent = nil)
      if node.nil?
        assert_options([nil, expected], os, os, 0, nil)
      else
        unless node.is_a?(OptionSet)
          # ensure correct option set
          assert_equal(os, node.option_set, 'incorrect option set')

          # ensure correct option level
          assert_equal(os.option_levels[depth - 1], node.option_level, "incorrect option level exp")

          # ensure correct parent
          assert_equal(parent, node.parent, 'incorrect parent')
        end

        # if expecting interior node
        if expected.is_a?(Array)
          # ensure node name is correct
          assert_equal(expected[0], node.option.name_en) unless expected[0].nil?

          # ensure correct number of children
          assert_equal(expected[1].size, node.optionings.size, 'incorrect number of children')

          # ensure children are correct (recursive step)
          expected[1].each_with_index do |e, idx|
            assert_options(e, os, node.optionings[idx], depth + 1, node.is_a?(OptionSet) ? nil : node)
          end

        # else, expecting leaf
        else
          assert_equal(expected, node.option.name_en)
          assert_equal([], node.optionings, 'should be leaf')
        end
      end
    end
end