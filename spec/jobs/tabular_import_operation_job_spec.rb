# frozen_string_literal: true

require "rails_helper"

describe TabularImportOperationJob do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:operation) { create(:operation, creator: user) }
  let(:upload) { create(:saved_upload, filename: filename) }

  context "with simple import" do
    let(:filename) { "single_group.csv" }

    it "succeeds" do
      described_class.perform_now(operation, saved_upload_id: upload.id, import_class: "UserImport")
      expect(operation.completed?).to be_truthy
      expect(operation.failed?).to be_falsey
    end
  end

  context "with simple validation error" do
    let(:filename) { "errors.xlsx" }

    it "handles errors gracefully" do
      described_class.perform_now(operation, saved_upload_id: upload.id, import_class: "UserImport")
      expect(operation.completed?).to be_truthy
      expect(operation.failed?).to be_truthy
      expect(operation.job_error_report).to match("* Row 2: Main Phone: Please enter at least 9 digits.\n* Row 3: Username: Please use only unaccented letters, numbers, periods, and underscores.")
    end
  end
end
