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

  test "user cannot manage UserBatch for a locked mission" do
    assert_equal(false, @admin.ability.can?(:manage, UserBatch))
  end

  test "user cannot delete a user from a locked mission" do
    assert_equal(false, @admin.ability.can?(:destroy, User))
  end

  #####
  # Coordinator Ability to manage Users Tests
  user_permissions = [:create, :login_instructions, :change_assignments]
  user_permissions.each do |user_permission|
    test "user cannot execute #{user_permission} on a User for a locked mission" do
      assert_equal(false, @coordinator.ability.can?(user_permission, User))
    end
  end

  #####
  # Coordinatory Ability to manage OptionSet, Form, Question, Questioning and OPtions
  lockable_managed_classes = [OptionSet, Form, Question, Questioning, Option]
  lockable_managed_classes.each do |lockable_managed_class|
    test "user cannot manage a new #{lockable_managed_class} for a locked mission" do
      assert_equal(false, @coordinator.ability.can?(:manage, lockable_managed_class))
    end
  end

  #####
  # admin user can view index, read and export classes for a locked mission
  admin_read_only_classes = [Form, Question, OptionSet]
  admin_read_only_classes.each do |admin_read_only_class|
    index_read_export_abilities = [:index, :read, :export]
    index_read_export_abilities.each do |ability|
      test "user can #{ability} on #{admin_read_only_class} for locked mission" do
        assert_equal(true, @admin.ability.can?(ability, admin_read_only_class))
      end
    end
  end

  #####
  # assign user to mission tests
  test "coordinator cannot assign user to on a locked Mission" do
    assert_equal(false, @coordinator.ability.can?(:assign_to, Mission, :id => @mission.id))
  end

  test "admin cannot assign user to a locked mission" do
    assert_equal(false, @admin.ability.can?(:assign_to, Mission))
  end

end
