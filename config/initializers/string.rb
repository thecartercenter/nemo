# frozen_string_literal: true

class String
  def is_number?
    true if Float(self)
  rescue StandardError
    false
  end

  def normalize
    unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/n, "")
  end

  # Temporary method to rid a string of pesky characters that might annoy Power BI.
  def vanilla
    normalize.gsub(/[^a-z0-9._\- ]/i, "").to_s
  end

  def ucwords
    split(" ").map(&:capitalize).join(" ")
  end
end
