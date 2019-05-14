# frozen_string_literal: true

require "rails_helper"

describe Constraint do
  it "has a valid factory" do
    create(:constraint)
  end

  describe "#inherit_mission" do
    let(:questioning) { create(:questioning, mission: create(:mission)) }
    subject { create(:constraint, mission: nil).mission }
    it { is_expected.to eq(questioning.mission) }
  end

  describe "validation" do
    describe "condition presence" do
      context "with no conditions" do
        subject(:constraint) { build(:constraint, no_conditions: true) }
        it { is_expected.to have_errors(conditions: "There must be at least one condition.") }
      end
    end
  end
end
