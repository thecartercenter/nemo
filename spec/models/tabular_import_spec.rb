# frozen_string_literal: true

require "rails_helper"

# Holds specs for code contained in TabularImport (parent class).
describe TabularImport do
  # Fake child class.
  class TestImport < TabularImport
    protected

    def process_data
      sheet.row[0] # Need to actually access some data to trip some errors.
    end
  end

  let(:file) { tabular_import_fixture(filename) }
  let(:import) { TestImport.new(file: file).tap(&:run) }
  let(:run_errors) { import.run_errors }

  context "with invalid file type" do
    let(:filename) { "not_tabular.jpg" }

    it "should correctly report error" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["There was an issue with your CSV file: Invalid byte sequence in UTF-8 in line 1."])
    end
  end

  context "with invalid CSV" do
    let(:filename) { "bad.csv" }

    it "should correctly report error" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["There was an issue with your CSV file: Unclosed quoted field in line 1."])
    end
  end

  context "with XLS file" do
    let(:filename) { "old_format.xls" }

    it "should correctly report error" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["There was an issue with your CSV file: Invalid byte sequence in UTF-8 in line 1."])
    end
  end
end
