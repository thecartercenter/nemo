# frozen_string_literal: true

require "rails_helper"

describe SkipRule do
  let(:form) { create(:form, question_types: %w[integer integer integer]) }

  describe "normalization" do
    describe "skip_if" do
      let(:skip_rule) do
        create(:skip_rule, submitted.merge(destination: "end", conditions_attributes: cond_attrs))
      end
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
      let(:rule) { build(:skip_rule, source_item: form.c[1], destination: "item", dest_item_id: nil) }

      it "should be required if destination is 'item'" do
        expect(rule).to have_errors(dest_item_id: /unless you choose 'skip to end of form'/)
      end
    end
  end
end
