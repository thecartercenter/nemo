require 'spec_helper'

describe 'abilities' do

  # user tests
  it 'coordinators should be able to create users for their current mission' do
    create_user_and_ability(:role => 'coordinator')

    u = User.new
    assert(@ability.cannot?(:create, u))
    u.assignments.build(:mission => get_mission)
    assert(@ability.can?(:create, u))
  end

  it 'staffers should not be able to create users' do
    create_user_and_ability(:role => 'staffer')

    u = User.new
    u.assignments.build(:mission => get_mission)
    assert(@ability.cannot?(:create, u))
  end

  # user and group tests
  it 'coordinators should be able to create groups for their current mission' do
    create_user_and_ability(:role => 'coordinator')

    g = Group.new
    assert(@ability.cannot?(:create, g))
    g.mission = get_mission
    assert(@ability.can?(:create, g))
  end

  it 'staffers should not be able to create groups' do
    create_user_and_ability(:role => 'staffer')

    g = Group.new(:mission => get_mission)
    assert(@ability.cannot?(:create, g))
  end

  # add user to groups tests
  it 'coordinators should not be able to add users to a group' do
    create_user_and_ability(:role => 'coordinator')

    g = Group.new
    g.mission = get_mission
    assert(@ability.can?(:create, g))

    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    assert(@ability.can?(:create, UserGroup))
  end

  it 'staffers should not be able to add users to a group' do
    create_user_and_ability(:role => 'staffer')

    g = Group.new
    g.mission = get_mission
    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    assert(@ability.cannot?(:create, UserGroup))
  end

  def create_user_and_ability(options)
    @user = FactoryGirl.create(:user, :role_name => options[:role])
    @ability = Ability.new(:user => @user, :mission => get_mission)
  end
end
