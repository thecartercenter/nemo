# frozen_string_literal: true

# Tests for abilities related to UserGroup object.
require "rails_helper"

describe "abilities for user_groups" do
  context "for coordinator role" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    it "should be able to create" do
      expect(ability).to be_able_to(:create, UserGroup)
      expect(ability).to be_able_to(:create, UserGroupAssignment)
    end

    it "should be able to possible_groups" do
      expect(ability).to be_able_to(:possible_groups, UserGroup)
    end
  end

  context "for enumerator role" do
    let(:user) { create(:user, role_name: "enumerator") }
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    it "should not be able to create" do
      expect(ability).not_to be_able_to(:create, UserGroup)
      expect(ability).not_to be_able_to(:create, UserGroupAssignment)
    end

    it "should be able to possible_groups" do
      expect(ability).to be_able_to(:possible_groups, UserGroup)
    end
  end
end
