# frozen_string_literal: true

require "rails_helper"

# Tests FormLogical behavior via SkipRule
describe FormLogical do
  let(:form) { create(:form, question_types: %w[integer integer integer]) }

  describe "normalization" do
    describe "rank" do
      let(:skip_rule) { create(:skip_rule, source_item: form.c[1]) }
      let!(:decoy_rule) { create(:skip_rule) } # On a different form/qing, ensures acts_as_list is scoped.
      subject { skip_rule.rank }

      context "when no other rules for this qing" do
        it { is_expected.to eq(1) }
      end

      context "when two other rules for this qing" do
        let!(:other_skip_rules) { create_list(:skip_rule, 2, source_item: form.c[1]) }
        it { is_expected.to eq(3) }
      end
    end

    describe "conditions" do
      let(:rule) do
        create(:skip_rule, source_item: form.c[1], conditions_attributes: [
          {left_qing_id: form.c[0].id, op: "eq", value: "5"},
          {left_qing_id: "", op: "", value: ""}
        ])
      end

      it "should be discarded if totally empty" do
        expect(rule.conditions.count).to eq(1)
        expect(rule.conditions[0].left_qing).to eq(form.c[0])
      end
    end
  end

  describe "#inherit_mission" do
    let(:questioning) { create(:questioning, mission: create(:mission)) }
    subject { create(:skip_rule, source_item: questioning, mission: nil).mission }
    it { is_expected.to eq(questioning.mission) }
  end

  describe "validation" do
    describe "condition validation passthrough" do
      let(:rule) do
        build(:skip_rule, source_item: form.c[1],
                          conditions_attributes: [{left_qing_id: form.c[0].id, op: "eq", value: ""}])
      end

      it "should set validation error if incomplete condition" do
        expect(rule).to have_errors("conditions.base": "All condition fields are required.")
        expect(rule.conditions[0]).to have_errors(base: "All condition fields are required.")
      end
    end
  end
end
