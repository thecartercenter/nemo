# frozen_string_literal: true

require "rails_helper"

BOM_BYTES = [239, 187, 191].freeze

describe UserFacingCSV do
  context "#open" do
    before do
      UserFacingCSV.open("/tmp/test.csv", "w+") do |csv|
        csv << ["id"]
        csv << ["1"]
      end
    end

    it "writes BOM before CSV content" do
      expect(File.read("/tmp/test.csv").bytes.slice(0, 3)).to eq(BOM_BYTES)
    end

    it "uses \r\n" do
      expect(File.read("/tmp/test.csv")).to include("id\r\n")
    end
  end

  context "#generate" do
    let(:generated_csv) do
      UserFacingCSV.generate do |csv|
        csv << ["id"]
        csv << ["1"]
      end
    end

    it "creates a CSV with BOM as first three bytes" do
      expect(generated_csv.bytes.slice(0, 3)).to eq(BOM_BYTES)
    end

    it "uses \r\n" do
      expect(generated_csv).to include("id\r\n")
    end
  end
end
