# frozen_string_literal: true

require "rails_helper"

describe ResponseCSVExportOperationJob do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:operation) { create(:operation, creator: user) }
  let(:csv) { operation.attachment.download }
  let!(:form) { create(:form, question_types: %w[integer select_one]) }
  let!(:responses) do
    [
      create(:response, form: form, answer_values: %w[1 Dog]),
      create(:response, form: form, answer_values: %w[2 Cat])
    ]
  end

  describe "#perform" do
    it "succeeds without search" do
      described_class.perform_now(operation)
      expect(csv).to match(/1,Dog/)
      expect(csv).to match(/2,Cat/)
    end

    it "succeeds with search" do
      described_class.perform_now(operation, search: "Cat")
      expect(csv).not_to match(/1,Dog/)
      expect(csv).to match(/2,Cat/)
    end

    it "handles search parse error gracefully" do
      described_class.perform_now(operation, search: "Cat:")
      expect(operation.job_failed_at).not_to be_nil
      expect(operation.job_error_report).to match(/Your search query could not be understood/)
    end
  end
end
