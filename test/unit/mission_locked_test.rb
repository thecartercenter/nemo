require 'test_helper'

# this class contains tests for the mission locked feature.
class MissionLockedTest < ActiveSupport::TestCase


  setup do
    @mission = FactoryGirl.create(:mission, :name => 'Locked mission')#, :locked => true)

    @admin = FactoryGirl.create(:user, :admin => true)

    @staffer = FactoryGirl.create(:user)
    @staffer.assignments.create(:mission => @mission, :active => true, :role => "staffer")

    @observer = FactoryGirl.create(:user)
    @observer.assignments.create(:mission => @mission, :active => true, :role => "observer")

    @coordinator = FactoryGirl.create(:user)
    @coordinator.assignments.create(:mission => @mission, :active => true, :role => "coordinator")

    @mission.locked = true
    @mission.save

    @admin.change_mission!(@mission)
    @staffer.change_mission!(@mission)
    @observer.change_mission!(@mission)
    @coordinator.change_mission!(@mission)
  end

  test "user cannot create a new option set for a locked mission" do
    option_set = FactoryGirl.build(:option_set, :mission => @mission)

    assert_equal(false, @admin.ability.can?(:create, OptionSet))
  end

end
