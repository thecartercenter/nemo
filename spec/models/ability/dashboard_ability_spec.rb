# frozen_string_literal: true

require "rails_helper"

describe "abilities for dashboard" do
  include_context "ability"

  let(:object) { :dashboard }
  let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

  context "for staffer" do
    let(:user) { create(:user, role_name: "staffer") }

    it "should be able to view" do
      expect(ability).to be_able_to(:view, :dashboard)
    end
  end

  context "for enumerator" do
    let(:user) { create(:user, role_name: "enumerator") }

    it "should not be able to view" do
      expect(ability).not_to be_able_to(:view, :dashboard)
    end
  end
end
