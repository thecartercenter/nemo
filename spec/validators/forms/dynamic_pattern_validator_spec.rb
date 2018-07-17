# frozen_string_literal: true

require "rails_helper"

describe Forms::DynamicPatternValidator do
  # This spec uses the Form model which uses this validator
  describe "calc_must_wrap_all_of_default_response_name" do
    shared_examples_for "valid" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    shared_examples_for "invalid" do
      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors[:default_response_name].join).to match(/must surround/)
      end
    end

    context "with regular name" do
      let(:form) { build(:form, default_response_name: "Foo") }
      it_behaves_like "valid"
    end

    context "with properly formatted calc" do
      let(:form) { build(:form, default_response_name: "calc($Foo + 4)") }
      it_behaves_like "valid"
    end

    context "with inner parens" do
      let(:form) { build(:form, default_response_name: "calc(if($Foo > 5, 'a', 'b'))") }
      it_behaves_like "valid"
    end

    context "with properly spaces around calc" do
      let(:form) { build(:form, default_response_name: " calc($Foo + 4)  ") }
      it_behaves_like "valid"
    end

    context "with calc at start but no paren at end" do
      let(:form) { build(:form, default_response_name: " calc($Foo + 4) Bananas") }
      it_behaves_like "invalid"
    end

    context "with calc not at start" do
      let(:form) { build(:form, default_response_name: "Item: calc($Foo + 4) ") }
      it_behaves_like "invalid"
    end
  end

  # This spec uses the Questioning model which sets force_calc_if: :numeric?
  describe "force_calc_for_dollar_refs_if" do
    context "with text question and non-calc pattern" do
      subject(:questioning) { build(:questioning, qtype_name: "text", default: "Hello $Foo") }
      it { is_expected.to be_valid }
    end

    context "with text question and calc pattern" do
      subject(:questioning) { build(:questioning, qtype_name: "text", default: "calc($Foo + 5)") }
      it { is_expected.to be_valid }
    end

    context "with int question and calc pattern" do
      subject(:questioning) { build(:questioning, qtype_name: "integer", default: "calc($Foo + 5)") }
      it { is_expected.to be_valid }
    end

    context "with int question and no dollar ref" do
      subject(:questioning) { build(:questioning, qtype_name: "integer", default: "-123") }
      it { is_expected.to be_valid }
    end

    context "with int question and non-calc pattern" do
      subject(:questioning) { build(:questioning, qtype_name: "integer", default: "Hello $Foo") }
      it do
        expect(questioning).not_to be_valid
        expect(questioning.errors[:default].join).to match(/must use the calc/)
      end
    end
  end
end
