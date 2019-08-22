# frozen_string_literal: true

# Creates CSVs with BOM.
class UserFacingCSV
  BOM = "\xEF\xBB\xBF"

  def self.generate(&block)
    CSV.generate(BOM.dup, &block)
  end

  def self.open(filename, mode = "rb", **options, &block)
    CSV.open(filename, mode, **options) do |csv|
      csv << [BOM]
      block.call(csv)
    end
  end
end
