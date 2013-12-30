require 'test_helper'

# this class contains tests for the mission locked feature.
class MissionLockedTest < ActiveSupport::TestCase


  setup do
    @mission = FactoryGirl.create(:mission, :name => 'Locked mission')

    @admin = FactoryGirl.create(:user, :admin => true)

    @observer = FactoryGirl.create(:user, :mission => @mission, :role_name => :observer)
    @staffer = FactoryGirl.create(:user, :mission => @mission, :role_name => :staffer)
    @coordinator = FactoryGirl.create(:user, :mission => @mission, :role_name => :coordinator)

    # also add the coordinator to a non-locked mission
    @coordinator.assignments.create!(:mission => get_mission, :role => 'coordinator')

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
  # coordinator ability to manage Users Tests
  test "user cannot create or update users for a locked mission" do
    # shouldn't be able to do these things to user in locked mission
    [:update, :login_instructions, :change_assignments].each do |p|
      assert_equal(false, @coordinator.ability.can?(p, @observer), "shouldn't be able to #{p} user")
    end

    # shouldn't be able to create a new user in locked mission
    @new_user = FactoryGirl.build(:user, :mission => @mission, :role_name => :observer)
    assert_equal(false, @coordinator.ability.can?(:create, @new_user), "shouldn't be able to create user")

    # should be able to create a new user in non-locked mission
    @coordinator.change_mission!(get_mission)
    @new_user = FactoryGirl.build(:user, :mission => get_mission, :role_name => :observer)
    assert_equal(true, @coordinator.ability.can?(:create, @new_user), "should be able to create user in regular mission")
  end

  #####
  # coordinator ability to manage OptionSet, Form, Question, Questioning and Options
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
  # staffer Response tests
  staffer_abilities_for_locked_mission = [:index, :read, :export]
  staffer_abilities_for_locked_mission.each do |staffer_ability|
    test "staffer can #{staffer_ability} Responses for a locked mission" do
      assert_equal(true, @staffer.ability.can?(staffer_ability, Response))
    end
  end

  test "staffer cannot manage Responses for a locked mission" do
    assert_equal(false, @staffer.ability.can?(:manage, Response))
  end

  #####
  # observer Response tests
  observer_abilities_for_locked_mission = [:index, :read, :export]
  observer_abilities_for_locked_mission.each do |observer_ability|
    test "observer can #{observer_ability} Responses for a locked mission" do
      assert_equal(true, @observer.ability.can?(observer_ability, Response))
    end
  end

  observer_inabilities_for_locked_mission = [:create, :update, :destroy]
  observer_inabilities_for_locked_mission.each do |observer_inability|
    test "observer cannot #{observer_inability} Responses for a locked mission" do
      assert_equal(false, @observer.ability.can?(observer_inability, Response))
    end
  end

  #####
  # assign User to Mission tests
  test "coordinator cannot assign user to on a locked Mission" do
    assert_equal(false, @coordinator.ability.can?(:assign_to, Mission, :id => @mission.id))
  end

  test "admin cannot assign user to a locked mission" do
    assert_equal(false, @admin.ability.can?(:assign_to, Mission))
  end

end
