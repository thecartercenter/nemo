# frozen_string_literal: true

require "rails_helper"

BOM_BYTES = [239, 187, 191].freeze

describe UserFacingCSV do
  context "#open" do
    it "writes BOM before CSV content" do
      UserFacingCSV.open("/tmp/test.csv", "w+") do |csv|
        csv << ["id"]
        csv << ["1"]
      end
      bytes = File.read("/tmp/test.csv").bytes.slice(0, 3)
      expect(bytes).to eq(BOM_BYTES)
    end
  end

  context "#generate" do
    it "creates a CSV with BOM as first three bytes" do
      generated_csv = UserFacingCSV.generate do |csv|
        csv << ["id"]
        csv << ["1"]
      end

      expect(generated_csv.bytes.slice(0, 3)).to eq(BOM_BYTES)
    end
  end
end
