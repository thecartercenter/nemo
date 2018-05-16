require "spec_helper"

describe BatchDestroy, type: :model do
  let(:user) { create(:user, mission: create(:mission)) }
  let(:current_user) { create(:user, email: "current@user.com") }
  let(:users) { create_list(:user, 3) }
  let(:ability) { Ability.new(user: current_user, mission: get_mission) }
  let(:destroyer) { BatchDestroy.new(users, current_user, ability) }

  describe "#destroy!" do
    it "deletes everyone but the current user" do
      users << current_user
      destroyer.destroy!

      # current user and user with a mission
      expect(User.count).to eq(1)
      expect(current_user.active).to be_truthy
    end

    it "deactivates everyone but the current user" do
      users << current_user << user
      destroyer.destroy!

      # users that exist but are not the current user should be deactivated
      User.where.not(email: "current@user.com").each do |u|
        expect(u.active).to be_falsey
      end

      # current user and user with a mission
      expect(User.count).to eq(2)
      expect(current_user.active).to be_truthy
    end
  end
end
