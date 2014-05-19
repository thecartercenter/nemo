require 'test_helper'

class OptionSetTest < ActiveSupport::TestCase

  test "creation" do
    # create the yes/no option set
    os = FactoryGirl.create(:option_set)
    os.reload
    assert(os.optionings.count > 0, "should have optionings")
    assert(os.options.count > 0, "should have options")
  end

  test "must have at least one option" do
    os = FactoryGirl.build(:option_set, :option_names => [])
    os.save
    assert_match(/at least one/, os.errors[:options].join)
  end

  #######################################################################
  # these rank tests are for single-level option sets
  # they should still pass even with multi-level architecture being added

  test "ranks changed" do
    os = FactoryGirl.create(:option_set, :option_names => %w(a b c d))
    assert_equal(false, os.positions_changed?)

    # changing rank should raise flag
    os.optionings[1].rank = 6
    assert_equal(true, os.positions_changed?)
    os.save!
    assert_equal(false, os.positions_changed?)

    # adding option set should also raise flag
    os.optionings.build(:rank => 8, :option => Option.new(:name => 'e'))
    assert_equal(true, os.positions_changed?)
    os.save!
  end

  test "creating an option set without explicit ranks should add default ranks" do
    os = create_option_set(["S", "V", "X"])
    assert_ranks(os, {"S" => 1, "V" => 2, "X" => 3})
  end

  test "creating an option set with explicit ranks should work regardless of submission order" do
    os = create_option_set({"S" => 2, "V" => 1, "X" => 3})
    assert_ranks(os, {"V" => 1, "S" => 2, "X" => 3})
  end

  test "editing an option set with invalid explicit ranks should correct them" do
    os = create_option_set({"S" => 1, "V" => 2, "X" => 3})

    # change the rank of 'V' to a too-high number
    os.optionings[1].rank = 9
    os.save!

    # the rank of 'V' should have been repaired down to 3, and 'X' should shift to 2
    assert_ranks(os, {"S" => 1, "X" => 2, "V" => 3})
  end

  test "a nullifyied rank should be corrected" do
    os = create_option_set({"S" => 1, "V" => 2, "X" => 3})

    # change the rank of 'V' to nil
    os.optionings[1].rank = nil
    os.save!

    # 'V' should move to the end
    assert_ranks(os, {"S" => 1, "X" => 2, "V" => 3})
  end

  test "options method should return properly sorted options" do
    os = create_option_set({"S" => 2, "V" => 1, "X" => 3})
    os.reload
    assert_equal("V", os.options[0].name_en)
    assert_equal("S", os.options[1].name_en)
    assert_equal("X", os.options[2].name_en)
  end

  test "ranks changed method should work" do
    os = create_option_set({"S" => 2, "V" => 1, "X" => 3})
    os.reload

    # make sure no false positive
    os.optionings[0].rank = 1
    assert_equal(false, os.positions_changed?)

    # make sure no false negative
    os.optionings[0].rank = 50
    assert_equal(true, os.positions_changed?)
  end

  #
  #######################################################################

  #######################################################################
  # these rank tests are for multi-level option sets

  test "ranks should be contiguous for all levels of multilevel option set" do
    # create the animal/plant option set
    os = FactoryGirl.create(:multilevel_option_set)

    # mess up ranks and save
    os.optionings[0].rank = 5
    os.optionings[1].rank = 3
    os.optionings[0].optionings[0].rank = 2
    os.optionings[0].optionings[1].rank = 5
    os.save!

    # check that ranks were repaired and the option arrays sorted
    assert_equal('plant', os.optionings[0].option.name)
    assert_equal([1,2], os.optionings.map(&:rank))
    assert_equal([1,2], os.optionings[0].optionings.map(&:rank))
  end

  test "positions_changed should work with multilevel option set" do
    # create the animal/plant option set
    os = FactoryGirl.create(:multilevel_option_set)

    assert_equal(false, os.positions_changed?)

    # switch the two first level options
    os.optionings[0].rank = 2
    os.optionings[1].rank = 1

    assert_equal(true, os.positions_changed?)
    os.save!
    assert_equal(false, os.positions_changed?)

    # switch the two rank 1 second level options (this is tricky since the rank numbers aren't changing)
    cat = os.optionings[0].optionings[0]
    pine = os.optionings[1].optionings[0]

    # move pine
    os.optionings[0].optionings[0] = pine
    pine.parent = os.optionings[0]

    # move cat
    os.optionings[1].optionings[0] = cat
    cat.parent = os.optionings[1]

    assert_equal(true, os.positions_changed?)
  end

  test "options_added should work with multilevel option set" do
    # create the animal/plant option set
    os = FactoryGirl.create(:multilevel_option_set)

    # should be false now because option set has been saved
    assert_equal(false, os.options_added?)

    # add another option
    os.optionings[1].optionings.build(:rank => 3, :option_set => os,
      :option => Option.new(:name => 'switchgrass'), :option_level => os.option_levels[1], :parent => os.optionings[1])

    # should be true now
    assert_equal(true, os.options_added?)

    os.save!

    # should be false again after save
    assert_equal(false, os.options_added?)
  end

  test "options_removed should with multilevel option set" do
    # create the animal/plant option set
    os = FactoryGirl.create(:multilevel_option_set)

    # should be false now because option set has been saved
    assert_equal(false, os.options_removed?)

    # remove an option (we use _destroy as that's how it will really happen)
    animal = os.optionings[0]
    cat = animal.optionings[0]

    os.assign_attributes('optionings_attributes' => {'0' => {
      'id' => animal.id.to_s,
      'optionings_attributes' => {'0' => {'id' => cat.id.to_s, '_destroy' => true}}
    }})

    # should be true now
    assert_equal(true, os.options_removed?)

    os.save!

    # delete should have worked
    assert_equal(1, os.optionings[0].optionings.size)

    # should be false again after save
    assert_equal(false, os.options_removed?)
  end

  #
  #######################################################################

  test "option level ranks should be contiguous" do
    os = FactoryGirl.create(:option_set)
    os.option_levels << FactoryGirl.build(:option_level, :option_set => os, :rank => 1)
    os.option_levels << FactoryGirl.build(:option_level, :option_set => os, :rank => 3)
    os.save!
    assert_equal([1,2], os.option_levels.map(&:rank))
  end

  test "multilevel option sets should have option levels" do
    os = FactoryGirl.build(:option_set, :multi_level => true)
    exception = assert_raise(RuntimeError) do
      os.valid?
    end
    assert_equal('multi-level option sets must have at least one option level', exception.to_s)
  end

  test "destroying an option set that is presently used in a question should raise deletion error" do
    os = FactoryGirl.create(:option_set)
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => os)
    assert_raise(DeletionError){os.reload.destroy}
  end

  test "creating an option set with nested paramters and a mix of new and existing options should work" do
    # create first option set so we can reuse options
    yn = FactoryGirl.create(:option_set)

    # submit with nested parameters
    os = OptionSet.create!(:mission => get_mission, :name => 'foo', :optionings_attributes => [
      {:rank => 2, :option_id => yn.options.first.id},
      {:rank => 1, :option_attributes => {:mission_id => get_mission.id, :name_en => "foo", :name_fr => "bar"}}
    ])

    # reload and test saved attributes of associations
    os.reload
    assert_equal('bar', os.options.first.name_fr)
    assert_equal('Yes', os.options.last.name_en)
    assert_equal(get_mission, os.options.last.mission)
  end

  test "updating an option set with nested paramters and adding a new option should work" do
    yn = FactoryGirl.create(:option_set)

    # update option set, changing ranks, and adding new option
    yn.update_attributes!(:optionings_attributes => [
      {:id => yn.optionings.last.id, :rank => 1, :option_id => yn.options.last.id},
      {:id => yn.optionings.first.id, :rank => 2, :option_id => yn.options.first.id},
      {:rank => 100, :option_attributes => {:mission_id => get_mission.id, :name_en => "foo", :name_fr => "bar"}}
    ])

    # test that option was added and rank was corrected
    yn.reload
    assert_equal(3, yn.optionings.size)
    assert_equal('No', yn.options[0].name_en)
    assert_equal('Yes', yn.options[1].name_en)
    assert_equal('foo', yn.options[2].name_en)
    assert_equal(3, yn.optionings[2].rank)
  end

  test "updating an option set with nested parameters and removing an option should work only if the option is unused" do
    os = FactoryGirl.create(:option_set)
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => os)

    # create published form with option set in it
    f = FactoryGirl.create(:form, :questions => [q], :published => true)

    # create a response that only uses the 'yes' option
    r = FactoryGirl.create(:response, :answers => [Answer.new(:questioning => f.questionings.first, :option => os.options.first)])

    # deleting the 'yes' option from the option set should raise a deletion error
    os.reload
    assert_raise(DeletionError){os.optionings.first.destroy}

    # deleting the unused 'no' option should not raise anything
    os.optionings.last.destroy
  end

  test "removing an option from an option set using nested paramters should work" do
    os = FactoryGirl.create(:option_set)

    # save the option that will be removed
    yes = os.options.first

    # remove it
    os.update_attributes!(:optionings_attributes => [
      {:id => os.optionings.first.id, :_destroy => true}
    ])

    # should only now be one option in set
    os.reload
    assert_equal(1, os.options.size)
    assert_equal('No', os.options.first.name_en)

    # yes option should still exist
    assert_not_nil(Option.find(yes.id))
  end

  test "creating an option set with no options should not validate" do
    assert_raise(ActiveRecord::RecordInvalid){OptionSet.create!(:mission => get_mission, :name => 'foo', :optionings_attributes => [])}
  end

  test "update an option set and removing all no options should not validate" do
    os = FactoryGirl.create(:option_set)

    # attempt to delete both option settings
    assert_raise(ActiveRecord::RecordInvalid) do
      os.update_attributes!(:optionings_attributes => [
        {:id => os.optionings.first.id, :_destroy => true},
        {:id => os.optionings.last.id, :_destroy => true}
      ])
    end
  end

  test "updating an option with all blank name translations should not validate" do
    os = FactoryGirl.create(:option_set)

    # attempt to blank out all name translations of the first option
    assert_raise(ActiveRecord::RecordInvalid) do
      os.update_attributes!(:optionings_attributes => [
        {:id => os.optionings[0].id, :rank => 1, :option_attributes => {:name_en => ''}}
      ])
    end

    # check that we get the right error msg (there should only be one entry in os.errors.messages)
    assert_equal(1, os.errors.messages.size)
    assert_equal(I18n.t('activerecord.errors.models.option.names_cant_be_all_blank'), os.errors.messages[:'optionings.option.base'].join)
  end

  test "newly added options should have mission id set" do
    yn = FactoryGirl.create(:option_set)
    assert_not_nil(yn.mission)

    # update option set, adding new option without mission id
    yn.update_attributes!(:optionings_attributes => [
      {:id => yn.optionings.last.id, :rank => 1, :option_id => yn.options.last.id},
      {:id => yn.optionings.first.id, :rank => 2, :option_id => yn.options.first.id},
      {:rank => 3, :option_attributes => {:name_en => "foo", :name_fr => "bar"}}
    ])

    # ensure new option has mission set
    yn.reload
    assert_not_nil(yn.options.last.mission_id)
  end

  test "cloning an option set within a mission should work" do
    yn = FactoryGirl.create(:option_set, :name => 'Foo')
    yn2 = yn.replicate(:mode => :clone)

    # missions should be the same
    assert_equal(yn.mission, yn2.mission)

    # options should be the same objects
    assert_equal(yn.options, yn2.options)

    # names should be different
    assert_not_equal(yn.name, yn2.name)
  end

  test "cloning a standard option set should work" do
    yn = FactoryGirl.create(:option_set, :name => 'Foo', :is_standard => true)
    yn2 = yn.replicate(:mode => :clone)
    yn.reload

    # missions should be the same (nil)
    assert_nil(yn2.mission)

    # new option set should be marked standard and have nil standard_id
    assert_equal(true, yn2.is_standard?)
    assert_nil(yn2.standard_id)

    # new and old optionings should all be marked standard and have nil missions and standard_ids
    assert_equal([true], yn.optionings.map(&:is_standard?).uniq)
    assert_equal([nil], yn.optionings.map(&:mission_id).uniq)
    assert_equal([nil], yn.optionings.map(&:standard_id).uniq)
    assert_equal([true], yn2.optionings.map(&:is_standard?).uniq)
    assert_equal([nil], yn2.optionings.map(&:mission_id).uniq)
    assert_equal([nil], yn2.optionings.map(&:standard_id).uniq)

    # options should be the same objects
    assert_equal(yn.options, yn2.options)

    # options should still be standard and null mission
    assert_equal([true], yn2.options.map(&:is_standard?).uniq)
    assert_equal([nil], yn2.options.map(&:mission_id).uniq)
    assert_equal([nil], yn2.options.map(&:standard_id).uniq)

    # names should be different
    assert_not_equal(yn.name, yn2.name)
  end

  private

    def create_option_set(options)
      # create empty set first
      os = FactoryGirl.build(:option_set, :name => 'Test', :option_names => [])

      options.each do |o|
        # if o is an array then we have an explicit rank
        if o.is_a?(Array)
          name = o[0]
          rank = o[1]
        # else we have no explicit rank, so leave nil
        else
          name = o
          rank = nil
        end
        os.optionings.build(:option => Option.new(:name_en => name, :mission => os.mission), :rank => rank, :mission => os.mission)
      end
      os.save!
      os
    end

    # checks that each rank is as expected
    def assert_ranks(os, ranks)
      os.optionings.each do |o|
        assert_equal(ranks[o.option.name_en], o.rank)
      end
    end
end