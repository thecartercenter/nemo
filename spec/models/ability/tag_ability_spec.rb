require 'rails_helper'

describe Tag do
  subject(:ability) do
    user = create(:user, role_name: 'coordinator')
    Ability.new(user: user, mission: get_mission)
  end

  before { @tag = build(:tag) }

  it { should be_able_to :update, @tag }
  it { should be_able_to :destroy, @tag }
end
