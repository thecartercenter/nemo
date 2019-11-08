# frozen_string_literal: true

require "rails_helper"

describe IntegrityWarnings::FormWarner do
  subject(:warnings) { described_class.new(form) }

  context "with fresh form" do
    let(:form) { create(:form) }

    it "returns no warnings" do
      expect(warnings.careful_with_changes).to be_empty
      expect(warnings.features_disabled).to be_empty
    end
  end

  context "with published form" do
    let(:form) { create(:form, :live, question_types: %w[text]) }

    context "with no responses" do
      it "returns warnings" do
        expect(warnings.careful_with_changes).to contain_exactly(:published)
        expect(warnings.features_disabled).to contain_exactly(:published)
      end
    end

    context "with responses" do
      let!(:response) { create(:response, form: form, answer_values: %w[x]) }

      it "returns warnings" do
        expect(warnings.careful_with_changes).to contain_exactly(:published)
        expect(warnings.features_disabled).to contain_exactly(:published, :has_data)
      end
    end
  end
end
