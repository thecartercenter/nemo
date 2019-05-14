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

    describe "condition validation passthrough" do
      let(:form) { create(:form, question_types: %w[integer]) }

      context "with incomplete condition" do
        let(:constraint) do
          build(:constraint, questioning: form.c[0],
                             conditions_attributes: [{ref_qing_id: form.c[0].id, op: "eq", value: ""}])
        end

        it "should set validation error" do
          expect(constraint).not_to be_valid
          expect(constraint.errors["conditions.base"].join).to eq("All condition fields are required.")
          expect(constraint.conditions[0].errors[:base].join).to eq("All condition fields are required.")
        end
      end
    end
  end
end
