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
end
