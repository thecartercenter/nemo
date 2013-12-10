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
    assert_match(/at least one/, os.errors.messages[:base].join)
  end
  
  test "optioning for" do
    os = FactoryGirl.create(:option_set, :option_names => %w(a b c d))
    assert_equal(os.optionings[2].id, os.optioning_for(os.options[2]).id)
  end
  
  test "ranks changed" do
    os = FactoryGirl.create(:option_set, :option_names => %w(a b c d))
    assert_equal(false, os.ranks_changed?)

    # changing rank should raise flag
    os.optionings[1].rank = 6
    assert_equal(true, os.ranks_changed?)
    os.save!
    assert_equal(false, os.ranks_changed?)
    
    # adding option set should also raise flag
    os.optionings.build(:rank => 8, :option => Option.new(:name => 'e'))
    assert_equal(true, os.ranks_changed?)
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
    assert_equal(false, os.ranks_changed?)
    
    # make sure no false negative
    os.optionings[0].rank = 50
    assert_equal(true, os.ranks_changed?)
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

  private
    def create_option_set(options)
      os = OptionSet.new(:name => "test")
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
        os.optionings.new(:option => Option.new(:name_en => name), :rank => rank)
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