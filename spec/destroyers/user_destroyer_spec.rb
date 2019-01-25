# frozen_string_literal: true

require "rails_helper"

describe UserDestroyer do
  let(:current_user) { create(:user, email: "current@user.com") }
  let(:ability) { Ability.new(user: current_user, mission: get_mission) }
  let!(:users) { create_list(:user, 3) }
  let!(:decoy) { users[0] }
  let!(:users_with_mission) { create_list(:user, 2, mission: create(:mission)) }
  let(:scope) { User.where.not(id: decoy.id) }
  let(:destroyer) { described_class.new(scope: scope, user: current_user, ability: ability) }
  let(:result) { destroyer.destroy! }

  it "ignores decoy user, skips current_user, deactivates users with other missions, deletes others" do
    expect(result).to eq(destroyed: 2, skipped: 1, deactivated: 2)
    expect(User.active.to_a).to contain_exactly(decoy, current_user)
    expect(User.inactive.to_a).to match_array(users_with_mission)
  end
end
