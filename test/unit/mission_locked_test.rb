require 'test_helper'

# this class contains tests for the mission locked feature.
class MissionLockedTest < ActiveSupport::TestCase

  setup do
    @locked = FactoryGirl.create(:mission, :name => 'Locked mission')
    @unlocked = get_mission

    @admin = FactoryGirl.create(:user, :admin => true)

    @obs = FactoryGirl.create(:user, :mission => @locked, :role_name => :observer)
    @staffer = FactoryGirl.create(:user, :mission => @locked, :role_name => :staffer)
    @coord = FactoryGirl.create(:user, :mission => @locked, :role_name => :coordinator)

    # also add the coordinator to a non-locked mission
    @coord.assignments.create!(:mission => get_mission, :role => 'coordinator')

    @locked.locked = true
    @locked.save
  end

  test "user cannot manage UserBatch for a locked mission" do
    assert_equal(false, admin_ability.can?(:manage, UserBatch))
  end

  test "user shouldnt be able to update users for a locked mission" do
    # shouldn't be able to do these things to user in locked mission
    [:update, :login_instructions, :change_assignments].each do |p|
      assert_equal(false, coord_locked_ability.can?(p, @obs), "shouldn't be able to #{p} user")
    end
  end

  test "coordinator shouldnt be able to create a new user in locked mission" do
    @new_user = FactoryGirl.build(:user, :mission => @locked, :role_name => :observer)
    assert_equal(false, coord_locked_ability.can?(:create, @new_user), "shouldn't be able to create user")
  end

  test "coordinator should be able to create a new user in non-locked mission" do
    @new_user = FactoryGirl.build(:user, :mission => @unlocked, :role_name => :observer)
    assert_equal(true, coord_unlocked_ability.can?(:create, @new_user), "should be able to create user in regular mission")
  end

  test "coordinator shouldnt be able to create update or destroy core classes for a locked mission" do
    [:option_set, :form, :question, :option].each do |klass|
      locked_obj = FactoryGirl.create(klass, :mission => @locked)
      normal_obj = FactoryGirl.create(klass, :mission => get_mission)
      [:create, :update, :destroy].each do |perm|
        assert_equal(false, coord_locked_ability.can?(perm, locked_obj), "shouldn't be able to #{perm} #{klass}")
        assert_equal(true, coord_unlocked_ability.can?(perm, normal_obj), "should be able to #{perm} #{klass}")
      end
    end
  end

  test "coordinator should be able to index read and export core classes for a locked mission" do
    [:form, :question, :option_set].each do |klass|
      obj = FactoryGirl.create(klass, :mission => @locked)
      [:index, :read, :export].each do |perm|
        assert_equal(true, coord_locked_ability.can?(perm, obj), "should be able to #{perm} #{klass}")
      end
    end
  end

  test "staffer should be able to index read and export responses for a locked mission" do
    resp = FactoryGirl.create(:response, :mission => @locked)
    [:index, :read, :export].each do |perm|
      assert_equal(true, staffer_locked_ability.can?(perm, resp))
    end
  end

  test "staffer shouldnt be able to create update or destroy responses for a locked mission" do
    resp = FactoryGirl.build(:response, :mission => @locked)
    [:create, :update, :destroy].each do |perm|
      assert_equal(false, staffer_locked_ability.can?(perm, resp))
    end
  end

  test "observer should be able to index read and export own responses for a locked mission" do
    resp = FactoryGirl.create(:response, :mission => @locked, :user => @obs)
    [:index, :read, :export].each do |perm|
      assert_equal(true, obs_locked_ability.can?(perm, resp))
    end
  end

  test "observer shouldnt be able to create update or destroy own responses for a locked mission" do
    resp = FactoryGirl.build(:response, :mission => @locked, :user => @obs)
    [:create, :update, :destroy].each do |perm|
      assert_equal(false, obs_locked_ability.can?(perm, resp))
    end
  end

  test "nobody should be able to assign a user to a locked Mission" do
    assert_equal(false, coord_locked_ability.can?(:assign_to, @locked))
    assert_equal(false, admin_ability.can?(:assign_to, @locked))
  end

  test "nobody should be able to edit an assignment on a locked mission" do
    # get the observers assignment to the locked mission
    assign = @obs.assignments.first
    assert_equal(false, admin_ability.can?(:update, assign))
  end

  test "admin should be able to edit an assignment on an unlocked mission" do
    assign2 = @obs.assignments.create(:mission => @unlocked, :role => 'observer')
    assert_equal(true, admin_ability.can?(:update, assign2))
  end

  private
    def admin_ability
      Ability.new(:user => @admin, :mode => 'admin')
    end

    def coord_unlocked_ability
      Ability.new(:user => @coord, :mission => @unlocked)
    end

    def coord_locked_ability
      Ability.new(:user => @coord, :mission => @locked)
    end

    def staffer_locked_ability
      Ability.new(:user => @staffer, :mission => @locked)
    end

    def obs_locked_ability
      Ability.new(:user => @obs, :mission => @locked)
    end
end
