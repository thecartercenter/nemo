require 'test_helper'

# this class contains tests for the mission locked feature.
class MissionLockedTest < ActiveSupport::TestCase


  setup do
    @mission = FactoryGirl.create(:mission, :name => 'Locked mission', :locked => true)
    @admin = FactoryGirl.create(:user, :admin => true)
    @admin.change_mission!(@mission)
  end

  test "user cannot create a new option set for a locked mission" do
    option_set = FactoryGirl.build(:option_set, :mission => @mission)

    assert_equal(false, @admin.ability.can?(:create, OptionSet))
  end

end