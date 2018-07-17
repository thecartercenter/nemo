require 'rails_helper'

describe Questioning do
  it "mission should get copied from question on creation" do
    f = create(:form, :question_types => %w(integer), :mission => get_mission)
    expect(f.questionings[0].mission).to eq(get_mission)
  end

  describe "normalization" do
    # Run valid? to trigger normalization
    let(:q_attrs) { {} }
    let(:question) { create(:question, q_attrs) }
    let(:qing) { build(:questioning, submitted.merge(question: question)).tap(&:valid?) }
    subject { submitted.keys.map { |k| [k, qing.send(k)] }.to_h }

    describe "hidden/required/read_only" do
      context do
        let(:submitted) { {hidden: true, required: true, read_only: false} }
        it { is_expected.to eq(hidden: true, required: false, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: true, required: false, read_only: false} }
        it { is_expected.to eq(hidden: true, required: false, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: false, required: true, read_only: false} }
        it { is_expected.to eq(hidden: false, required: true, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: false, required: true, read_only: true} }
        it { is_expected.to eq(hidden: false, required: false, read_only: true) }
      end

      context do
        let(:submitted) { {hidden: false, required: false, read_only: true} }
        it { is_expected.to eq(hidden: false, required: false, read_only: true) }
      end
    end

    describe "question metadata and hidden/required" do
      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {required: true, hidden: false} }
        it { is_expected.to eq(required: false, hidden: true) }
      end

      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {required: "", hidden: true} }
        it { is_expected.to eq(required: false, hidden: true) }
      end

      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: ""} }
        let(:submitted) { {required: true, hidden: false} }
        it { is_expected.to eq(required: true, hidden: false) }
      end
    end

    describe "question metadata and condition" do
      let(:condition) { build(:condition) }

      context "not adding a metadata_type"do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: nil} }
        let(:submitted) { {display_conditions: [condition]} }
        it "should not destroy existing conditions" do
          is_expected.to eq(display_conditions: [condition])
        end
      end

      context "add a metadata_type with an existing condition" do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {display_conditions: [condition]} }
        it "should destroy existing conditions" do
          is_expected.to eq(display_conditions: [])
          expect(condition).to be_destroyed
        end
      end

      context "add a metadata_type with no existing conditions" do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {display_conditions: []} }
        it "should not change the display conditions" do
          is_expected.to eq(display_conditions: [])
        end
      end
    end
  end

  describe "validation" do
    # Detailed testing of this validator is in own file.
    describe "DynamicPatternValidator" do
      let(:questioning) { build(:questioning, default: "Item: calc($Foo + 4) ") }

      it "is hooked up properly" do
        expect(questioning).to be_invalid
        expect(questioning.errors[:default].join).to match(/must surround/)
      end
    end
  end
end
