# frozen_string_literal: true

# Creates CSVs with BOM.
class UserFacingCSV
  BOM = "\xEF\xBB\xBF"

  def self.generate(**options, &block)
    CSV.generate(BOM.dup, &block)
  end

  def self.open(filename, mode = "rb", **options, &block)
    # Prepend BOM.
    unless mode.include?("r")
      File.open(filename, mode) do |f|
        f << BOM
      end
    end
    CSV.open(filename, "ab", options, &block)
  end
end
