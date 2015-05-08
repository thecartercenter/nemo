require 'spec_helper'

# this class contains tests for the mission locked feature.
describe MissionLocked do

  before do
    @locked = create(:mission, :name => 'Locked mission')
    @unlocked = get_mission

    @admin = create(:user, :admin => true)

    @obs = create(:user, :mission => @locked, :role_name => :observer)
    @staffer = create(:user, :mission => @locked, :role_name => :staffer)
    @coord = create(:user, :mission => @locked, :role_name => :coordinator)

    # also add the coordinator to a non-locked mission
    @coord.assignments.create!(:mission => get_mission, :role => 'coordinator')

    @locked.locked = true
    @locked.save
  end

  it "user cannot manage UserBatch for a locked mission" do
    expect(UserBatch)).to eq(false, admin_ability.can?(:manage)
  end

  it "user shouldnt be able to update users for a locked mission" do
    # shouldn't be able to do these things to user in locked mission
    [:update, :login_instructions, :change_assignments].each do |p|
      expect("shouldn't be able to #{p} user").to eq(false, coord_locked_ability.can?(p, @obs))
    end
  end

  it "coordinator shouldnt be able to create a new user in locked mission" do
    @new_user = build(:user, :mission => @locked, :role_name => :observer)
    expect("shouldn't be able to create user").to eq(false, coord_locked_ability.can?(:create, @new_user))
  end

  it "coordinator should be able to create a new user in non-locked mission" do
    @new_user = build(:user, :mission => @unlocked, :role_name => :observer)
    expect("should be able to create user in regular mission").to eq(true, coord_unlocked_ability.can?(:create, @new_user))
  end

  it "coordinator shouldnt be able to create update or destroy core classes for a locked mission" do
    [:option_set, :form, :question, :option].each do |klass|
      locked_obj = create(klass, :mission => @locked)
      normal_obj = create(klass, :mission => get_mission)
      [:create, :update, :destroy].each do |perm|
        expect("shouldn't be able to #{perm} #{klass}").to eq(false, coord_locked_ability.can?(perm, locked_obj))
        expect("should be able to #{perm} #{klass}").to eq(true, coord_unlocked_ability.can?(perm, normal_obj))
      end
    end
  end

  it "coordinator should be able to index read and export core classes for a locked mission" do
    [:form, :question, :option_set].each do |klass|
      obj = create(klass, :mission => @locked)
      [:index, :read, :export].each do |perm|
        expect("should be able to #{perm} #{klass}").to eq(true, coord_locked_ability.can?(perm, obj))
      end
    end
  end

  it "staffer should be able to index read and export responses for a locked mission" do
    resp = create(:response, :mission => @locked)
    [:index, :read, :export].each do |perm|
      expect(resp)).to eq(true, staffer_locked_ability.can?(perm)
    end
  end

  it "staffer shouldnt be able to create update or destroy responses for a locked mission" do
    resp = build(:response, :mission => @locked)
    [:create, :update, :destroy].each do |perm|
      expect(resp)).to eq(false, staffer_locked_ability.can?(perm)
    end
  end

  it "observer should be able to index read and export own responses for a locked mission" do
    resp = create(:response, :mission => @locked, :user => @obs)
    [:index, :read, :export].each do |perm|
      expect(resp)).to eq(true, obs_locked_ability.can?(perm)
    end
  end

  it "observer shouldnt be able to create update or destroy own responses for a locked mission" do
    resp = build(:response, :mission => @locked, :user => @obs)
    [:create, :update, :destroy].each do |perm|
      expect(resp)).to eq(false, obs_locked_ability.can?(perm)
    end
  end

  it "nobody should be able to assign a user to a locked Mission" do
    expect(@locked)).to eq(false, coord_locked_ability.can?(:assign_to)
    expect(@locked)).to eq(false, admin_ability.can?(:assign_to)
  end

  it "nobody should be able to edit an assignment on a locked mission" do
    # get the observers assignment to the locked mission
    assign = @obs.assignments.first
    expect(assign)).to eq(false, admin_ability.can?(:update)
  end

  it "admin should be able to edit an assignment on an unlocked mission" do
    assign2 = @obs.assignments.create(:mission => @unlocked, :role => 'observer')
    expect(assign2)).to eq(true, admin_ability.can?(:update)
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
