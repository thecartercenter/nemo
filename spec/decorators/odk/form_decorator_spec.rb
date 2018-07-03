# frozen_string_literal: true

require "spec_helper"

# Form decorator spec
describe Odk::FormDecorator, :odk, :reset_factory_sequences do
  describe "needs_manifest?" do
    let(:decorated_form) { decorate(form) }

    context "for form with single level option sets only" do
      let(:form) { create(:form, question_types: %w[select_one]) }
      it "should return false" do
        expect(decorated_form.needs_manifest?).to be_falsey
      end
    end

    context "for form with multi level option set" do
      let(:form) { create(:form, question_types: %w[select_one multilevel_select_one]) }
      it "should return true" do
        expect(decorated_form.needs_manifest?).to be_truthy
      end
    end
  end
end
