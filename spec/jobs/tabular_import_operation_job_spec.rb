# frozen_string_literal: true

require "rails_helper"

# This spec just covers the handling of errors and etc. The specifics of which inputs cause which errors
# should be handled in other specs specific to each import type.
describe TabularImportOperationJob do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:operation) { create(:operation, creator: user) }
  let(:upload) { create(:saved_upload, filename: filename) }

  context "with simple import" do
    let(:filename) { "single_group.csv" }

    it "succeeds" do
      described_class.perform_now(operation, saved_upload_id: upload.id, import_class: "UserImport")
      expect(operation.completed?).to be(true)
      expect(operation.failed?).to be(false)
    end
  end

  context "with simple validation error" do
    let(:filename) { "errors.csv" }

    it "handles errors gracefully" do
      described_class.perform_now(operation, saved_upload_id: upload.id, import_class: "UserImport")
      expect(operation.completed?).to be(true)
      expect(operation.failed?).to be(true)
      expect(operation.job_error_report).to match("* Row 2: Main Phone: Please enter at least 9 digits."\
        "\n* Row 3: Username: Please use only letters, numbers, periods, and underscores.")
    end
  end
end
