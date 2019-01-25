# frozen_string_literal: true

require "rails_helper"

describe UserDestroyer do
  let(:current_user) { create(:user, email: "current@user.com") }
  let(:ability) { Ability.new(user: current_user, mission: get_mission) }
  let(:destroyer) { UserDestroyer.new(rel: batch, user: current_user, ability: ability) }
  let(:users) { create_list(:user, 3) }
  let(:user) { create(:user, mission: create(:mission)) }
  let(:batch) { users }

  it "deletes everyone but the current user" do
    users << current_user
    destroyer.destroy!

    expect(User.all.to_a).to contain_exactly(current_user)
  end

  it "deactivates user with mission and skips current user" do
    users << current_user << user
    destroyer.destroy!

    # users that exist but are not the current user should be deactivated
    User.where.not(email: "current@user.com").each do |u|
      expect(u).not_to be_active
    end

    # current user and user with a mission
    expect(User.all.to_a).to contain_exactly(current_user, user)
  end
end
