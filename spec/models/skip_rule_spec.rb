require 'rails_helper'

describe SkipRule do
  let(:form) { create(:form, question_types: %w(integer integer integer)) }
  let(:qing1) { form.c[0] }
  let(:qing2) { form.c[1] }
  let(:qing3) { form.c[2] }

  describe "normalization" do
    describe "rank" do
      let(:skip_rule) { create(:skip_rule, source_item: qing2) }
      let!(:decoy_rule) { create(:skip_rule) } # On a different form/qing, ensures acts_as_list is scoped.
      subject { skip_rule.rank }

      context "when no other rules for this qing" do
        it { is_expected.to eq 1 }
      end

      context "when two other rules for this qing" do
        let!(:other_skip_rules) { create_list(:skip_rule, 2, source_item: qing2) }
        it { is_expected.to eq 3 }
      end
    end

    describe "conditions" do
      it "should be discarded if totally empty" do
        rule = create(:skip_rule, source_item: qing2, conditions_attributes: [
          {ref_qing_id: qing1.id, op: "eq", value: "5"},
          {ref_qing_id: "", op: "", value: ""}
        ])
        expect(rule.conditions.count).to eq 1
        expect(rule.conditions[0].ref_qing).to eq qing1
      end
    end

    describe "skip_if" do
      let(:skip_rule) { create(:skip_rule,
        submitted.merge(destination: "end", conditions_attributes: cond_attrs)) }
      let(:ref_qing) { create(:questioning) }
      subject { submitted.keys.map { |k| [k, skip_rule.send(k)] }.to_h }

      context "with no conditions" do
        let(:cond_attrs) { [] }

        context do
          let(:submitted) { {skip_if: "all_met"} }
          it { is_expected.to eq(skip_if: "always") }
        end

        context do
          let(:submitted) { {skip_if: "any_met"} }
          it { is_expected.to eq(skip_if: "always") }
        end

        context do
          let(:submitted) { {skip_if: "always"} }
          it { is_expected.to eq(skip_if: "always") }
        end
      end

      context "with blank condition" do
        let(:cond_attrs) { [{ref_qing_id: "", op: "", value: "  "}] }

        context do
          let(:submitted) { {skip_if: "all_met"} }
          it { is_expected.to eq(skip_if: "always") }
        end
      end

      context "with partial condition" do
        let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "", value: "  "}] }
        let(:submitted) { {skip_if: "all_met"} }

        it "should fail validation" do
          expect { skip_rule }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "with full condition" do
        let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "eq", value: "foo"}] }

        context do
          let(:submitted) { {skip_if: "all_met"} }
          it { is_expected.to eq(skip_if: "all_met") }
        end

        context do
          let(:submitted) { {skip_if: "any_met"} }
          it { is_expected.to eq(skip_if: "any_met") }
        end

        context do
          let(:submitted) { {skip_if: "always"} }
          it { is_expected.to eq(skip_if: "all_met") }
        end
      end
    end
  end

  describe "validation" do
    describe "dest_item" do
      it "should be required if destination is 'item'" do
        rule = build(:skip_rule, source_item: qing2, destination: "item", dest_item_id: nil)
        expect(rule).not_to be_valid
        expect(rule.errors[:dest_item_id].join).to match /unless you choose 'skip to end of form'/
      end
    end

    describe "conditions" do
      it "should set validation error if incomplete condition" do
        rule = build(:skip_rule, source_item: qing2, conditions_attributes: [
          {ref_qing_id: qing1.id, op: "eq", value: ""}
        ])
        expect(rule).not_to be_valid
        expect(rule.errors["conditions.base"].join).to eq "All condition fields are required."
        expect(rule.conditions[0].errors[:base].join).to eq "All condition fields are required."
      end
    end
  end
end
