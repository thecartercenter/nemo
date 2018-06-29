require 'rails_helper'

describe "abilities for locked missions" do

  before(:all) do
    @locked = create(:mission, name: 'Locked mission')
    @unlocked = get_mission

    @admin = create(:user, admin: true)

    @obs = create(:user, mission: @locked, role_name: :enumerator)
    @staffer = create(:user, mission: @locked, role_name: :staffer)
    @coord = create(:user, mission: @locked, role_name: :coordinator)

    # also add the coordinator to a non-locked mission
    @coord.assignments.create!(mission: get_mission, role: 'coordinator')

    # Can't set it to locked until now because otherwise we encounter issues creating the above.
    @locked.locked = true
    @locked.save
  end

  it "user cannot manage UserBatch for a locked mission" do
    expect(admin_ability.can?(:manage, UserBatch)).to eq(false)
  end

  it "user shouldnt be able to update users for a locked mission" do
    # shouldn't be able to do these things to user in locked mission
    [:update, :login_instructions, :change_assignments].each do |p|
      expect(coord_locked_ability.can?(p, @obs)).to eq(false), "shouldn't be able to #{p} user"
    end
  end

  it "coordinator shouldnt be able to create a new user in locked mission" do
    @new_user = build(:user, mission: @locked, role_name: :enumerator)
    expect(coord_locked_ability.can?(:create, @new_user)).to eq(false), "shouldn't be able to create user"
  end

  it "coordinator should be able to create a new user in non-locked mission" do
    @new_user = build(:user, mission: @unlocked, role_name: :enumerator)
    expect(coord_unlocked_ability.can?(:create, @new_user)).to eq(true), "should be able to create user in regular mission"
  end

  it "coordinator shouldnt be able to create update or destroy core classes for a locked mission" do
    [:option_set, :form, :question, :option].each do |klass|
      locked_obj = create(klass, mission: @locked)
      normal_obj = create(klass, mission: get_mission)
      [:create, :update, :destroy].each do |perm|
        expect(coord_locked_ability.can?(perm, locked_obj)).to eq(false), "shouldn't be able to #{perm} #{klass}"
        expect(coord_unlocked_ability.can?(perm, normal_obj)).to eq(true), "should be able to #{perm} #{klass}"
      end
    end
  end

  it "coordinator should be able to index read and export core classes for a locked mission" do
    [:form, :question, :option_set].each do |klass|
      obj = create(klass, mission: @locked)
      [:index, :read, :export].each do |perm|
        expect(coord_locked_ability.can?(perm, obj)).to eq(true), "should be able to #{perm} #{klass}"
      end
    end
  end

  it "staffer should be able to index read and export responses for a locked mission" do
    resp = create(:response, mission: @locked)
    [:index, :read, :export].each do |perm|
      expect(staffer_locked_ability.can?(perm, resp)).to eq(true)
    end
  end

  it "staffer shouldnt be able to create update or destroy responses for a locked mission" do
    resp = build(:response, mission: @locked)
    [:create, :update, :destroy].each do |perm|
      expect(staffer_locked_ability.can?(perm, resp)).to eq(false)
    end
  end

  it "enumerator should be able to index and read own responses for a locked mission" do
    resp = create(:response, mission: @locked, user: @obs)
    [:index, :read].each do |perm|
      expect(obs_locked_ability.can?(perm, resp)).to eq(true)
    end
  end

  it "enumerator shouldnt be able to create update or destroy own responses for a locked mission" do
    resp = build(:response, mission: @locked, user: @obs)
    [:create, :update, :destroy].each do |perm|
      expect(obs_locked_ability.can?(perm, resp)).to eq(false)
    end
  end

  it "nobody should be able to assign a user to a locked Mission" do
    expect(coord_locked_ability.can?(:assign_to, @locked)).to eq(false)
    expect(admin_ability.can?(:assign_to, @locked)).to eq(false)
  end

  it "nobody should be able to edit an assignment on a locked mission" do
    # get the enumerators assignment to the locked mission
    assign = @obs.assignments.first
    expect(admin_ability.can?(:update, assign)).to eq(false)
  end

  it "admin should be able to edit an assignment on an unlocked mission" do
    assign2 = @obs.assignments.create(mission: @unlocked, role: 'enumerator')
    expect(admin_ability.can?(:update, assign2)).to eq(true)
  end

  private

  def admin_ability
    Ability.new(user: @admin, mode: 'admin')
  end

  def coord_unlocked_ability
    Ability.new(user: @coord, mission: @unlocked)
  end

  def coord_locked_ability
    Ability.new(user: @coord, mission: @locked)
  end

  def staffer_locked_ability
    Ability.new(user: @staffer, mission: @locked)
  end

  def obs_locked_ability
    Ability.new(user: @obs, mission: @locked)
  end
end
