# frozen_string_literal: true

require "rails_helper"

# This spec uses the Form model which uses this validator
describe Forms::DynamicPatternValidator do
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
end
