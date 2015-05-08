require 'spec_helper'

describe 'abilities' do

  # user tests
  it 'coordinators should be able to create users for their current mission' do
    create_user_and_ability(:role => 'coordinator')

    u = User.new
    expect(@ability.cannot?(:create, u)).to be true
    u.assignments.build(:mission => get_mission)
    expect(@ability.can?(:create, u)).to be true
  end

  it 'staffers should not be able to create users' do
    create_user_and_ability(:role => 'staffer')

    u = User.new
    u.assignments.build(:mission => get_mission)
    expect(@ability.cannot?(:create, u)).to be true
  end

  # user and group tests
  it 'coordinators should be able to create groups for their current mission' do
    create_user_and_ability(:role => 'coordinator')

    g = Group.new
    expect(@ability.cannot?(:create, g)).to be true
    g.mission = get_mission
    expect(@ability.can?(:create, g)).to be true
  end

  it 'staffers should not be able to create groups' do
    create_user_and_ability(:role => 'staffer')

    g = Group.new(:mission => get_mission)
    expect(@ability.cannot?(:create, g)).to be true
  end

  # add user to groups tests
  it 'coordinators should not be able to add users to a group' do
    create_user_and_ability(:role => 'coordinator')

    g = Group.new
    g.mission = get_mission
    expect(@ability.can?(:create, g)).to be true

    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    expect(@ability.can?(:create, UserGroup)).to be true
  end

  it 'staffers should not be able to add users to a group' do
    create_user_and_ability(:role => 'staffer')

    g = Group.new
    g.mission = get_mission
    u = FactoryGirl.create(:user, :name => "Ada Nu User")
    expect(@ability.cannot?(:create, UserGroup)).to be true
  end

  def create_user_and_ability(options)
    @user = FactoryGirl.create(:user, :role_name => options[:role])
    @ability = Ability.new(:user => @user, :mission => get_mission)
  end
end
