shared_context "conditionable" do
  shared_examples_for "display_if with conditions" do
    let(:ref_qing) { create(:questioning) }

    # This is the attributes that result after normalization.
    subject { submitted.keys.map { |k| [k, conditionable.send(k)] }.to_h }

    context "with no conditions" do
      let(:cond_attrs) { [] }

      context do
        let(:submitted) { {display_if: "all_met"} }
        it { is_expected.to eq(display_if: "always") }
      end

      context do
        let(:submitted) { {display_if: "any_met"} }
        it { is_expected.to eq(display_if: "always") }
      end

      context do
        let(:submitted) { {display_if: "always"} }
        it { is_expected.to eq(display_if: "always") }
      end
    end

    context "with blank condition" do
      let(:cond_attrs) { [{ref_qing_id: "", op: "", value: "  "}] }

      context do
        let(:submitted) { {display_if: "all_met"} }
        it { is_expected.to eq(display_if: "always") }

        it "should discard condition" do
          expect(conditionable.display_conditions).to be_empty
        end
      end
    end

    context "with partial condition" do
      let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "", value: "  "}] }
      let(:submitted) { {display_if: "all_met"} }

      it "should fail validation" do
        expect { conditionable }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with full condition" do
      let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "eq", value: "foo"}] }

      context do
        let(:submitted) { {display_if: "all_met"} }
        it { is_expected.to eq(display_if: "all_met") }
      end

      context do
        let(:submitted) { {display_if: "any_met"} }
        it { is_expected.to eq(display_if: "any_met") }
      end

      context do
        let(:submitted) { {display_if: "always"} }
        it { is_expected.to eq(display_if: "all_met") }
      end
    end
  end
end
