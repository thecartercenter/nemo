# frozen_string_literal: true

require "rails_helper"

describe Constraint do
  it "has a valid factory" do
    create(:constraint)
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
