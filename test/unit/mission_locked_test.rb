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

    # need special ability object for admin with admin mode set to true
    @admin_ability = Ability.new(@admin, true)
  end

  test "user cannot manage UserBatch for a locked mission" do
    assert_equal(false, @admin.ability.can?(:manage, UserBatch))
  end

  test "user cannot delete a user from a locked mission" do
    assert_equal(false, @admin.ability.can?(:destroy, User))
  end

  #####
  # coordinator ability to manage Users Tests
  test "user shouldnt be able to update users for a locked mission" do
    # shouldn't be able to do these things to user in locked mission
    [:update, :login_instructions, :change_assignments].each do |p|
      assert_equal(false, @coordinator.ability.can?(p, @observer), "shouldn't be able to #{p} user")
    end
  end

  test "coordinator shouldnt be able to create a new user in locked mission" do
    @new_user = FactoryGirl.build(:user, :mission => @mission, :role_name => :observer)
    assert_equal(false, @coordinator.ability.can?(:create, @new_user), "shouldn't be able to create user")
  end

  test "coordinator should be able to create a new user in non-locked mission" do
    @coordinator.change_mission!(get_mission)
    @new_user = FactoryGirl.build(:user, :mission => get_mission, :role_name => :observer)
    assert_equal(true, @coordinator.ability.can?(:create, @new_user), "should be able to create user in regular mission")
  end

  test "coordinator shouldnt be able to create update or destroy core classes for a locked mission" do
    [:option_set, :form, :question, :questioning, :option].each do |klass|
      locked_obj = FactoryGirl.build(klass, :mission => @mission)
      normal_obj = FactoryGirl.build(klass, :mission => get_mission)
      [:create, :update, :destroy].each do |perm|
        @coordinator.change_mission!(@mission)
        assert_equal(false, @coordinator.ability.can?(perm, locked_obj), "shouldn't be able to #{perm} #{klass}")
        @coordinator.change_mission!(get_mission)
        assert_equal(true, @coordinator.ability.can?(perm, normal_obj), "should be able to #{perm} #{klass}")
      end
    end
  end

  test "coordinator should be able to index read and export core classes for a locked mission" do
    [:form, :question, :option_set].each do |klass|
      obj = FactoryGirl.build(klass, :mission => @mission)
      [:index, :read, :export].each do |perm|
        assert_equal(true, @coordinator.ability.can?(perm, obj), "should be able to #{perm} #{klass}")
      end
    end
  end

  test "staffer should be able to index read and export responses for a locked mission" do
    resp = FactoryGirl.create(:response, :mission => @mission)
    [:index, :read, :export].each do |perm|
      assert_equal(true, @staffer.ability.can?(perm, resp))
    end
  end

  test "staffer shouldnt be able to create update or destroy responses for a locked mission" do
    resp = FactoryGirl.build(:response, :mission => @mission)
    [:create, :update, :destroy].each do |perm|
      assert_equal(false, @staffer.ability.can?(perm, resp))
    end
  end

  test "observer should be able to index read and export own responses for a locked mission" do
    resp = FactoryGirl.create(:response, :mission => @mission, :user => @observer)
    [:index, :read, :export].each do |perm|
      assert_equal(true, @observer.ability.can?(perm, resp))
    end
  end

  test "observer shouldnt be able to create update or destroy own responses for a locked mission" do
    resp = FactoryGirl.build(:response, :mission => @mission, :user => @observer)
    [:create, :update, :destroy].each do |perm|
      assert_equal(false, @observer.ability.can?(perm, resp))
    end
  end

  test "nobody should be able to assign a user to a locked Mission" do
    assert_equal(false, @coordinator.ability.can?(:assign_to, @mission))
    assert_equal(false, @admin.ability.can?(:assign_to, @mission))
  end

  test "nobody should be able to edit an assignment on a locked mission" do
    # get the observers assignment to the locked mission
    assign = @observer.assignments.first
    assert_equal(false, @admin_ability.can?(:update, assign))
    assign2 = @observer.assignments.create(:mission => get_mission, :role => 'observer')
    assert_equal(true, @admin_ability.can?(:update, assign2))
  end
end
