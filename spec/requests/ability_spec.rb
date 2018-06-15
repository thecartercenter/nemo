require "rails_helper"

describe "abilities" do

  # user tests
  it "coordinators should be able to create users for their current mission" do
    create_user_and_ability(role: "coordinator")

    u = User.new
    expect(@ability.cannot?(:create, u)).to be true
    u.assignments.build(mission: get_mission)
    expect(@ability.can?(:create, u)).to be true
  end

  it "staffers should not be able to create users" do
    create_user_and_ability(role: "staffer")

    u = User.new
    u.assignments.build(mission: get_mission)
    expect(@ability.cannot?(:create, u)).to be true
  end

  def create_user_and_ability(options)
    @user = FactoryGirl.create(:user, role_name: options[:role])
    @ability = Ability.new(user: @user, mission: get_mission)
  end
end
