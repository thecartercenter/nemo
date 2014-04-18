require 'test_helper'

class AbilityTest < ActiveSupport::TestCase

  # user tests
  test 'coordinators should be able to create users for their current mission' do
    coord = FactoryGirl.create(:user, :role_name => 'coordinator')
    coord.set_current_mission
    a = Ability.new(coord)

    u = User.new
    assert(a.cannot?(:create, u))
    u.assignments.build(:mission => coord.current_mission)
    assert(a.can?(:create, u))
  end

  test 'staffers should not be able to create users' do
    staffer = FactoryGirl.create(:user, :role_name => 'staffer')
    staffer.set_current_mission
    a = Ability.new(staffer)

    u = User.new
    assert(a.cannot?(:create, u))
    u.assignments.build(:mission => staffer.current_mission)
    assert(a.cannot?(:create, u))
  end

  # user and group tests
  test 'coordinators should be able to create groups for their current mission' do
    coord = FactoryGirl.create(:user, :role_name => 'coordinator')
    coord.set_current_mission
    a = Ability.new(coord)

    g = Group.new
    assert(a.cannot?(:create, g))
    g.mission = coord.current_mission
    assert(a.can?(:create, g))
  end

  test 'staffers should not be able to create groups' do
    staffer = FactoryGirl.create(:user, :role_name => 'staffer')
    staffer.set_current_mission
    a = Ability.new(staffer)

    g = Group.new
    assert(a.cannot?(:create, g))
    g.mission = staffer.current_mission
    assert(a.cannot?(:create, g))
  end

  # add user to groups tests
  test 'coordinators are able to add users to a group' do
    coord = FactoryGirl.create(:user, :role_name => 'coordinator')
    coord.set_current_mission
    a = Ability.new(coord)

    g = Group.new
    g.mission = coord.current_mission
    assert(a.can?(:create, g))

    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    assert(a.can?(:create, UserGroup))
  end

  test 'staffers are not able to add users to a group' do
    staffer = FactoryGirl.create(:user, :role_name => 'staffer')
    staffer.set_current_mission
    a = Ability.new(staffer)

    g = Group.new
    g.mission = staffer.current_mission

    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    assert(a.cannot?(:create, UserGroup))
  end


end
