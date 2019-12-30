# frozen_string_literal: true

class String
  def is_number?
    true if Float(self)
  rescue StandardError
    false
  end

  def normalize
    mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, "")
  end

  def ucwords
    split(" ").map(&:capitalize).join(" ")
  end
end
